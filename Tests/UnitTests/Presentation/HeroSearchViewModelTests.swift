import XCTest
@testable import SuperHeroBattle

final class HeroSearchViewModelTests: XCTestCase {
    @MainActor
    func testSuccessfulSearchPublishesResults() async {
        let hero = makeHero(id: "1", name: "Batman")
        let viewModel = makeViewModel(outcome: .success([hero]))

        viewModel.query = "batman"
        viewModel.submit()

        XCTAssertEqual(viewModel.state, .loading)
        await waitForState(viewModel) { $0 == .results([hero]) }
        XCTAssertEqual(viewModel.state, .results([hero]))
    }

    @MainActor
    func testEmptyResultsPublishEmptyState() async {
        let viewModel = makeViewModel(outcome: .success([]))

        viewModel.query = "unknown"
        viewModel.submit()

        await waitForState(viewModel) { $0 == .empty }
        XCTAssertEqual(viewModel.state, .empty)
    }

    @MainActor
    func testTransportFailurePublishesOfflineFailure() async {
        let viewModel = makeViewModel(outcome: .failure(.transport))

        viewModel.query = "batman"
        viewModel.submit()

        await waitForState(viewModel) { $0 == .failure(.offline) }
        XCTAssertEqual(viewModel.state, .failure(.offline))
    }

    @MainActor
    func testNotConfiguredFailureIsPresented() async {
        let viewModel = makeViewModel(outcome: .failure(.notConfigured))

        viewModel.query = "batman"
        viewModel.submit()

        await waitForState(viewModel) { $0 == .failure(.notConfigured) }
        XCTAssertEqual(viewModel.state, .failure(.notConfigured))
    }

    @MainActor
    func testNotFoundBecomesEmptyInsteadOfFailure() async {
        let viewModel = makeViewModel(outcome: .failure(.notFound))

        viewModel.query = "batman"
        viewModel.submit()

        await waitForState(viewModel) { $0 == .empty }
        XCTAssertEqual(viewModel.state, .empty)
    }

    @MainActor
    func testCancellationErrorReturnsToIdle() async {
        let viewModel = makeViewModel(outcome: .cancellation)

        viewModel.query = "batman"
        viewModel.submit()

        XCTAssertEqual(viewModel.state, .loading)
        await waitForState(viewModel) { $0 == .idle }
        XCTAssertEqual(viewModel.state, .idle)
    }

    @MainActor
    func testClearCancelsAndResetsSearch() async {
        let repository = ControlledHeroRepository()
        let viewModel = HeroSearchViewModel(
            searchHeroes: SearchHeroesUseCase(repository: repository)
        )
        let started = expectation(description: "search started")
        repository.onSearchStart { _ in started.fulfill() }

        viewModel.query = "batman"
        viewModel.submit()
        await fulfillment(of: [started], timeout: 2)

        viewModel.clear()

        XCTAssertEqual(viewModel.query, "")
        XCTAssertEqual(viewModel.state, .idle)

        repository.complete(query: "batman", heroes: [makeHero(id: "1", name: "Batman")])
        await settle()

        XCTAssertEqual(viewModel.state, .idle)
    }

    @MainActor
    func testRetryRunsSearchAgainAfterFailure() async {
        let hero = makeHero(id: "1", name: "Batman")
        let repository = ScriptedHeroRepository([
            .failure(.server(status: 500)),
            .success([hero]),
        ])
        let viewModel = HeroSearchViewModel(
            searchHeroes: SearchHeroesUseCase(repository: repository)
        )

        viewModel.query = "batman"
        viewModel.submit()
        await waitForState(viewModel) { $0 == .failure(.server) }

        viewModel.retry()
        await waitForState(viewModel) { $0 == .results([hero]) }

        XCTAssertEqual(viewModel.state, .results([hero]))
        let queries = repository.recordedQueries()
        XCTAssertEqual(queries, ["batman", "batman"])
    }

    @MainActor
    func testOutdatedResponseDoesNotOverwriteNewSearch() async {
        let oldHero = makeHero(id: "1", name: "Batman")
        let newHero = makeHero(id: "2", name: "Superman")
        let repository = ControlledHeroRepository()
        let viewModel = HeroSearchViewModel(
            searchHeroes: SearchHeroesUseCase(repository: repository)
        )

        let oldStarted = expectation(description: "old search started")
        let newStarted = expectation(description: "new search started")
        repository.onSearchStart { query in
            if query == "batman" {
                oldStarted.fulfill()
            } else if query == "superman" {
                newStarted.fulfill()
            }
        }

        viewModel.query = "batman"
        viewModel.submit()
        await fulfillment(of: [oldStarted], timeout: 2)

        viewModel.query = "superman"
        viewModel.submit()
        await fulfillment(of: [newStarted], timeout: 2)

        repository.complete(query: "superman", heroes: [newHero])
        repository.complete(query: "batman", heroes: [oldHero])

        await waitForState(viewModel) { $0 == .results([newHero]) }
        XCTAssertEqual(viewModel.state, .results([newHero]))
    }

    @MainActor
    func testCancelActiveSearchKeepsPublishedResults() async {
        let hero = makeHero(id: "1", name: "Batman")
        let viewModel = makeViewModel(outcome: .success([hero]))

        viewModel.query = "batman"
        viewModel.submit()
        await waitForState(viewModel) { $0 == .results([hero]) }

        viewModel.cancelActiveSearch()

        XCTAssertEqual(viewModel.state, .results([hero]))
    }

    @MainActor
    func testBlankQueryClearsInsteadOfSearching() async {
        let repository = CountingHeroRepository(heroes: [])
        let viewModel = HeroSearchViewModel(
            searchHeroes: SearchHeroesUseCase(repository: repository)
        )

        viewModel.query = "   "
        viewModel.submit()
        await settle()

        XCTAssertEqual(viewModel.state, .idle)
        let count = repository.count()
        XCTAssertEqual(count, 0)
    }

    @MainActor
    private func makeViewModel(outcome: StubHeroOutcome) -> HeroSearchViewModel {
        HeroSearchViewModel(
            searchHeroes: SearchHeroesUseCase(repository: StubHeroRepository(outcome: outcome))
        )
    }

    @MainActor
    private func waitForState(
        _ viewModel: HeroSearchViewModel,
        timeout: Int = 2,
        predicate: @escaping (HeroSearchState) -> Bool
    ) async {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(timeout))

        while clock.now < deadline {
            if predicate(viewModel.state) {
                return
            }
            await Task.yield()
        }

        XCTFail("State did not satisfy predicate. Current: \(viewModel.state)")
    }

    @MainActor
    private func settle() async {
        for _ in 0..<50 {
            await Task.yield()
        }
    }

    private func makeHero(id: String, name: String) -> Hero {
        Hero(id: id, name: name)
    }
}

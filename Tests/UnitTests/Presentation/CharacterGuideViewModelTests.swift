import XCTest
@testable import SuperHeroBattle

final class CharacterGuideViewModelTests: XCTestCase {
    @MainActor
    func testLoadsFirstPageOfThirtyIDs() async {
        let viewModel = makeViewModel(ids: makeIDs(count: 65))

        viewModel.loadIfNeeded()
        await waitFor(viewModel) { $0.catalogHeroes.count == 30 }

        XCTAssertEqual(viewModel.totalCharacterCount, 65)
        XCTAssertEqual(viewModel.catalogHeroes.map(\.id), makeIDs(count: 65).prefix(30).map { $0 })
        XCTAssertTrue(viewModel.hasMorePages)
        XCTAssertFalse(viewModel.isLoadingPage)
        XCTAssertNil(viewModel.pageFailure)
    }

    @MainActor
    func testPaginatesUntilTheEndWithoutDuplicates() async {
        let viewModel = makeViewModel(ids: makeIDs(count: 65))

        viewModel.loadIfNeeded()
        await waitFor(viewModel) { $0.catalogHeroes.count == 30 }

        viewModel.loadNextPage()
        await waitFor(viewModel) { $0.catalogHeroes.count == 60 }

        viewModel.loadNextPage()
        await waitFor(viewModel) { $0.catalogHeroes.count == 65 }

        XCTAssertEqual(viewModel.catalogHeroes.map(\.id), makeIDs(count: 65))
        XCTAssertEqual(Set(viewModel.catalogHeroes.map(\.id)).count, 65)
        XCTAssertFalse(viewModel.hasMorePages)
    }

    @MainActor
    func testPrefetchesWhenApproachingTheEndOfTheVisibleList() async {
        let viewModel = makeViewModel(ids: makeIDs(count: 65))

        viewModel.loadIfNeeded()
        await waitFor(viewModel) { $0.catalogHeroes.count == 30 }

        let trigger = viewModel.catalogHeroes[30 - CharacterGuideViewModel.prefetchThreshold]
        viewModel.prefetchIfNeeded(currentHero: trigger)

        await waitFor(viewModel) { $0.catalogHeroes.count == 60 }
        XCTAssertEqual(viewModel.catalogHeroes.count, 60)
    }

    @MainActor
    func testEarlyHeroDoesNotTriggerPrefetch() async {
        let viewModel = makeViewModel(ids: makeIDs(count: 65))

        viewModel.loadIfNeeded()
        await waitFor(viewModel) { $0.catalogHeroes.count == 30 }

        viewModel.prefetchIfNeeded(currentHero: viewModel.catalogHeroes[0])
        await settle()

        XCTAssertEqual(viewModel.catalogHeroes.count, 30)
    }

    @MainActor
    func testPageFailureKeepsCursorAndRetryLoadsTheSamePage() async {
        let ids = makeIDs(count: 65)
        let heroes = makeHeroes(ids: ids)
        let remote = SwitchableHeroRepository(.failure(.transport))
        let catalog = InMemoryHeroCatalogRepository()
        let viewModel = CharacterGuideViewModel(
            characterIDs: StubCharacterIDProvider(ids: ids),
            loadHeroes: LoadHeroesByIDsUseCase(catalog: catalog, remote: remote),
            searchHeroes: SearchHeroesUseCase(repository: remote)
        )

        viewModel.loadIfNeeded()
        await waitFor(viewModel) { $0.pageFailure == .offline }

        XCTAssertTrue(viewModel.catalogHeroes.isEmpty)
        XCTAssertTrue(viewModel.hasMorePages)

        await remote.setOutcome(.success(heroes))
        viewModel.retryPage()
        await waitFor(viewModel) { $0.catalogHeroes.count == 30 }

        XCTAssertNil(viewModel.pageFailure)
        XCTAssertEqual(viewModel.catalogHeroes.map(\.id), Array(ids.prefix(30)))
    }

    @MainActor
    func testMissingIndexShowsUnavailableFailure() async {
        let viewModel = makeViewModel(
            provider: StubCharacterIDProvider(ids: [], error: .resourceMissing)
        )

        viewModel.loadIfNeeded()
        await settle()

        XCTAssertEqual(viewModel.catalogFailure, .unavailable)
    }

    @MainActor
    func testEmptyIndexShowsEmptyFailure() async {
        let viewModel = makeViewModel(
            provider: StubCharacterIDProvider(ids: [], error: .empty)
        )

        viewModel.loadIfNeeded()
        await settle()

        XCTAssertEqual(viewModel.catalogFailure, .empty)
    }

    @MainActor
    func testSearchModeAndClearReturnToCatalog() async {
        let ids = makeIDs(count: 35)
        let heroes = makeHeroes(ids: ids)
        let viewModel = makeViewModel(ids: ids, heroes: heroes)

        viewModel.loadIfNeeded()
        await waitFor(viewModel) { $0.catalogHeroes.count == 30 }

        viewModel.search.query = "batman"
        viewModel.submitSearch()

        XCTAssertTrue(viewModel.isSearching)
        await waitFor(viewModel) { $0.search.state == .results(heroes) }
        XCTAssertEqual(viewModel.search.state, .results(heroes))

        viewModel.clearSearch()

        XCTAssertFalse(viewModel.isSearching)
        XCTAssertEqual(viewModel.search.state, .idle)
        XCTAssertEqual(viewModel.catalogHeroes.count, 30)
    }

    @MainActor
    func testFiltersApplyOnlyToLoadedHeroes() async {
        let ids = makeIDs(count: 35)
        let viewModel = makeViewModel(ids: ids, heroes: makeHeroes(ids: ids))

        viewModel.loadIfNeeded()
        await waitFor(viewModel) { $0.catalogHeroes.count == 30 }

        viewModel.selectPublisher("DC Comics")

        XCTAssertTrue(viewModel.hasActiveFilters)
        XCTAssertEqual(viewModel.filteredHeroes.count, 15)
        XCTAssertTrue(viewModel.filteredHeroes.allSatisfy { $0.publisher == "DC Comics" })

        viewModel.clearFilters()

        XCTAssertFalse(viewModel.hasActiveFilters)
        XCTAssertEqual(viewModel.filteredHeroes.count, 30)
    }

    @MainActor
    private func makeViewModel(
        ids: [String] = [],
        heroes: [Hero]? = nil,
        provider: StubCharacterIDProvider? = nil
    ) -> CharacterGuideViewModel {
        let resolvedHeroes = heroes ?? makeHeroes(ids: ids)
        let remote = StubHeroRepository(outcome: .success(resolvedHeroes))
        return CharacterGuideViewModel(
            characterIDs: provider ?? StubCharacterIDProvider(ids: ids),
            loadHeroes: LoadHeroesByIDsUseCase(
                catalog: InMemoryHeroCatalogRepository(),
                remote: remote
            ),
            searchHeroes: SearchHeroesUseCase(repository: remote)
        )
    }

    @MainActor
    private func waitFor(
        _ viewModel: CharacterGuideViewModel,
        timeout: Int = 2,
        predicate: @escaping (CharacterGuideViewModel) -> Bool
    ) async {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(timeout))

        while clock.now < deadline {
            if predicate(viewModel) {
                return
            }
            await Task.yield()
        }

        XCTFail("La condición no se cumplió. Estado actual: \(viewModel.catalogHeroes.count) héroes")
    }

    @MainActor
    private func settle() async {
        for _ in 0..<60 {
            await Task.yield()
        }
    }

    private func makeIDs(count: Int) -> [String] {
        (1...count).map(String.init)
    }

    private func makeHeroes(ids: [String]) -> [Hero] {
        ids.enumerated().map { index, id in
            Hero(
                id: id,
                name: "Hero \(id)",
                biography: HeroBiography(
                    publisher: index.isMultiple(of: 2) ? "DC Comics" : "Marvel"
                ),
                appearance: HeroAppearance(
                    gender: index.isMultiple(of: 2) ? "Male" : "Female"
                )
            )
        }
    }
}

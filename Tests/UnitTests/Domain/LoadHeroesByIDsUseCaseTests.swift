import XCTest
@testable import SuperHeroBattle

final class LoadHeroesByIDsUseCaseTests: XCTestCase {
    func testUsesCachedHeroesBeforeRemote() async throws {
        let cached = [makeHero(id: "1"), makeHero(id: "2")]
        let catalog = SpyCatalogRepository(heroes: cached)
        let remote = GatedHeroRepository(heroes: [])
        let useCase = LoadHeroesByIDsUseCase(catalog: catalog, remote: remote)

        let heroes = try await useCase.execute(ids: ["1", "2"])

        XCTAssertEqual(heroes.map(\.id), ["1", "2"])
        let started = remote.startedIDs()
        XCTAssertTrue(started.isEmpty)
        let upserted = catalog.upsertedIDs()
        XCTAssertTrue(upserted.isEmpty)
    }

    func testFetchesOnlyMissingIDsAndPreservesRequestedOrder() async throws {
        let cached = [makeHero(id: "2")]
        let all = (1...3).map { makeHero(id: String($0)) }
        let catalog = SpyCatalogRepository(heroes: cached)
        let remote = StubHeroRepository(outcome: .success(all))
        let useCase = LoadHeroesByIDsUseCase(catalog: catalog, remote: remote)

        let heroes = try await useCase.execute(ids: ["1", "2", "3"])

        XCTAssertEqual(heroes.map(\.id), ["1", "2", "3"])
        let upserted = catalog.upsertedIDs().sorted()
        XCTAssertEqual(upserted, ["1", "3"])
    }

    func testNotFoundIsSkippedWithoutFailingThePage() async throws {
        let heroes = [makeHero(id: "1"), makeHero(id: "3")]
        let catalog = SpyCatalogRepository()
        let remote = StubHeroRepository(outcome: .success(heroes))
        let useCase = LoadHeroesByIDsUseCase(catalog: catalog, remote: remote)

        let result = try await useCase.execute(ids: ["1", "2", "3"])

        XCTAssertEqual(result.map(\.id), ["1", "3"])
    }

    func testRemoteFailurePropagatesButCachesSuccessfulHeroes() async throws {
        let catalog = SpyCatalogRepository()
        let remote = PerIDHeroRepository(
            heroes: [makeHero(id: "1")],
            failures: ["2": .transport]
        )
        let useCase = LoadHeroesByIDsUseCase(catalog: catalog, remote: remote)

        do {
            _ = try await useCase.execute(ids: ["1", "2"])
            XCTFail("Se esperaba un error")
        } catch {
            XCTAssertEqual(error as? HeroRepositoryError, .transport)
        }

        let stored = catalog.storedIDs()
        XCTAssertEqual(stored, ["1"])
    }

    func testCancellationPropagates() async {
        let catalog = SpyCatalogRepository()
        let remote = SwitchableHeroRepository(.cancellation)
        let useCase = LoadHeroesByIDsUseCase(catalog: catalog, remote: remote)

        do {
            _ = try await useCase.execute(ids: ["1"])
            XCTFail("Se esperaba cancelación")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }

    func testConcurrencyIsCappedAtConfiguredLimit() async throws {
        let ids = (1...20).map(String.init)
        let heroes = ids.map { makeHero(id: $0) }
        let catalog = SpyCatalogRepository()
        let remote = GatedHeroRepository(heroes: heroes)
        let useCase = LoadHeroesByIDsUseCase(
            catalog: catalog,
            remote: remote,
            maxConcurrentRequests: 6
        )

        let task = Task {
            try await useCase.execute(ids: ids)
        }

        await waitUntil { remote.startedIDs().count == 6 }
        let maxConcurrent = remote.maxConcurrent()
        XCTAssertEqual(maxConcurrent, 6)

        for _ in 0..<40 {
            if remote.startedIDs().count == ids.count,
               remote.pendingCount() == 0 {
                break
            }
            remote.completeAllPending()
            await settle()
        }

        remote.completeAllPending()
        let result = try await task.value
        XCTAssertEqual(result.map(\.id), ids)
    }

    private func waitUntil(
        timeout: TimeInterval = 2,
        condition: @escaping () async -> Bool
    ) async {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(timeout))

        while clock.now < deadline {
            if await condition() {
                return
            }
            await Task.yield()
        }

        XCTFail("La condición no se cumplió a tiempo")
    }

    private func settle() async {
        for _ in 0..<20 {
            await Task.yield()
        }
    }

    private func makeHero(id: String) -> Hero {
        Hero(id: id, name: "Hero \(id)")
    }
}

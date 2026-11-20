import XCTest
@testable import SuperHeroBattle

final class DrawRandomHeroesUseCaseTests: XCTestCase {
    func testDrawsTheRequestedCountFromTheIndex() async throws {
        let useCase = makeUseCase(ids: (1...100).map(String.init))

        let outcome = try await useCase.execute(count: 6)

        XCTAssertEqual(outcome.heroes.count, 6)
        XCTAssertEqual(outcome.drawnIDs.count, 6)
        XCTAssertEqual(Set(outcome.drawnIDs).count, 6, "Los IDs sorteados no se repiten")
    }

    func testExcludedIDsAreNeverDrawn() async throws {
        let ids = (1...10).map(String.init)
        let excluded: Set<String> = ["1", "2", "3", "4", "5", "6", "7", "8"]
        let useCase = makeUseCase(ids: ids)

        let outcome = try await useCase.execute(count: 5, excluding: excluded)

        XCTAssertEqual(Set(outcome.drawnIDs), ["9", "10"], "Solo los no excluidos se sortean")
        XCTAssertEqual(outcome.heroes.count, 2)
    }

    func testCountLargerThanIndexReturnsEverythingAvailable() async throws {
        let useCase = makeUseCase(ids: ["1", "2", "3"])

        let outcome = try await useCase.execute(count: 10)

        XCTAssertEqual(Set(outcome.drawnIDs), ["1", "2", "3"])
    }

    func testZeroCountYieldsEmptyOutcomeWithoutRequests() async throws {
        let remote = GatedHeroRepository(heroes: [])
        let useCase = makeUseCase(ids: ["1", "2"], remote: remote)

        let outcome = try await useCase.execute(count: 0)

        XCTAssertEqual(outcome.heroes, [])
        XCTAssertEqual(outcome.drawnIDs, [])

        let started = await remote.startedIDs()
        XCTAssertTrue(started.isEmpty, "Con count 0 no debe lanzarse ninguna petición")
    }

    func testEmptyIndexYieldsEmptyOutcome() async throws {
        let useCase = makeUseCase(ids: [])

        let outcome = try await useCase.execute(count: 4)

        XCTAssertEqual(outcome.heroes, [])
        XCTAssertEqual(outcome.drawnIDs, [])
    }

    func testDrawnIDsIncludeIDsThatDidNotResolve() async throws {
        // "3" does not exist in the remote: it is drawn but does not resolve to a hero.
        let roster = ["1", "2"].map { makeHero(id: $0) }
        let useCase = makeUseCase(ids: ["1", "2", "3"], remote: StubHeroRepository(outcome: .success(roster)))

        let outcome = try await useCase.execute(count: 3)

        XCTAssertEqual(outcome.heroes.map(\.id).sorted(), ["1", "2"])
        XCTAssertEqual(Set(outcome.drawnIDs), ["1", "2", "3"], "Los notFound también cuentan como sorteados")
    }

    func testIndexFailurePropagates() async {
        let useCase = makeUseCase(
            ids: [],
            provider: StubCharacterIDProvider(ids: [], error: .unreadable)
        )

        do {
            _ = try await useCase.execute(count: 2)
            XCTFail("El error del índice debe propagarse")
        } catch {
            XCTAssertEqual(error as? CharacterIDProviderError, .unreadable)
        }
    }

    func testLoaderFailurePropagates() async {
        let useCase = makeUseCase(ids: ["1", "2"], remote: StubHeroRepository(outcome: .failure(.transport)))

        do {
            _ = try await useCase.execute(count: 2)
            XCTFail("El error de carga debe propagarse")
        } catch {
            XCTAssertEqual(error as? HeroRepositoryError, .transport)
        }
    }

    func testCancellationPropagatesInsteadOfFallingBack() async {
        let remote = SwitchableHeroRepository(.cancellation)
        let useCase = makeUseCase(ids: ["1", "2"], remote: remote)

        do {
            _ = try await useCase.execute(count: 2)
            XCTFail("La cancelación debe propagarse")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }

    // MARK: - Helpers

    private func makeUseCase(
        ids: [String],
        provider: (any CharacterIDProviding)? = nil,
        remote: (any HeroRepository)? = nil,
        picker: (any RandomIDPicker)? = nil
    ) -> DrawRandomHeroesUseCase {
        let roster = ids.map { makeHero(id: $0) }
        let resolvedRemote = remote ?? StubHeroRepository(outcome: .success(roster))
        let resolvedProvider = provider ?? StubCharacterIDProvider(ids: ids)
        let resolvedPicker = picker ?? SequentialIDPicker()

        return DrawRandomHeroesUseCase(
            characterIDs: resolvedProvider,
            loadHeroes: LoadHeroesByIDsUseCase(
                catalog: InMemoryHeroCatalogRepository(),
                remote: resolvedRemote
            ),
            picker: resolvedPicker
        )
    }

    private func makeHero(id: String) -> Hero {
        Hero(id: id, name: "Hero \(id)")
    }
}

/// Deterministic picker: returns the first available IDs in order.
private struct SequentialIDPicker: RandomIDPicker {
    func pickIDs(from ids: [String], excluding excludedIDs: Set<String>, count: Int) -> [String] {
        Array(ids.filter { !excludedIDs.contains($0) }.prefix(count))
    }
}

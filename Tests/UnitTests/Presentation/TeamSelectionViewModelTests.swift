import XCTest
@testable import SuperHeroBattle

@MainActor
final class TeamSelectionViewModelTests: XCTestCase {
    func testInitialDraftsAreEmptyForMode() {
        let viewModel = makeViewModel(mode: .threeVsThree)

        XCTAssertTrue(viewModel.teamA.heroes.isEmpty)
        XCTAssertTrue(viewModel.teamB.heroes.isEmpty)
        XCTAssertFalse(viewModel.bothTeamsComplete)
        XCTAssertNil(viewModel.battleParticipants)
    }

    func testAssignFillsOnlyRequestedSlot() {
        let viewModel = makeViewModel(mode: .twoVsTwo)

        viewModel.assign(makeHero(id: "7"), to: .teamA, slot: 1)

        XCTAssertEqual(viewModel.hero(in: 1, side: .teamA)?.id, "7")
        XCTAssertNil(viewModel.hero(in: 0, side: .teamA))
        XCTAssertNil(viewModel.message)
    }

    func testReplaceKeepsOtherSlots() {
        let viewModel = makeViewModel(mode: .twoVsTwo)

        viewModel.assign(makeHero(id: "1"), to: .teamA, slot: 0)
        viewModel.assign(makeHero(id: "2"), to: .teamA, slot: 1)
        viewModel.assign(makeHero(id: "3"), to: .teamA, slot: 0)

        XCTAssertEqual(viewModel.hero(in: 0, side: .teamA)?.id, "3")
        XCTAssertEqual(viewModel.hero(in: 1, side: .teamA)?.id, "2")
    }

    func testDuplicateInsideTeamIsRejectedWithMessage() {
        let viewModel = makeViewModel(mode: .twoVsTwo)

        viewModel.assign(makeHero(id: "1"), to: .teamA, slot: 0)
        viewModel.assign(makeHero(id: "1"), to: .teamA, slot: 1)

        XCTAssertEqual(viewModel.message, .duplicateHero)
        XCTAssertNil(viewModel.hero(in: 1, side: .teamA))
    }

    func testSameHeroIsAllowedInBothTeams() {
        let viewModel = makeViewModel(mode: .oneVsOne)

        viewModel.assign(makeHero(id: "5"), to: .teamA, slot: 0)
        viewModel.assign(makeHero(id: "5"), to: .teamB, slot: 0)

        XCTAssertNil(viewModel.message)
        XCTAssertEqual(viewModel.hero(in: 0, side: .teamA)?.id, "5")
        XCTAssertEqual(viewModel.hero(in: 0, side: .teamB)?.id, "5")
    }

    func testClearEmptiesOnlyRequestedSlot() {
        let viewModel = makeViewModel(mode: .twoVsTwo)
        viewModel.assign(makeHero(id: "1"), to: .teamB, slot: 0)
        viewModel.assign(makeHero(id: "2"), to: .teamB, slot: 1)

        viewModel.clear(side: .teamB, slot: 0)

        XCTAssertNil(viewModel.hero(in: 0, side: .teamB))
        XCTAssertEqual(viewModel.hero(in: 1, side: .teamB)?.id, "2")
    }

    func testBattleParticipantsNilUntilBothTeamsComplete() {
        let viewModel = makeViewModel(mode: .twoVsTwo)

        viewModel.assign(makeHero(id: "1"), to: .teamA, slot: 0)
        viewModel.assign(makeHero(id: "2"), to: .teamA, slot: 1)
        XCTAssertNil(viewModel.battleParticipants)

        viewModel.assign(makeHero(id: "3"), to: .teamB, slot: 0)
        XCTAssertNil(viewModel.battleParticipants)

        viewModel.assign(makeHero(id: "4"), to: .teamB, slot: 1)

        let participants = viewModel.battleParticipants
        XCTAssertEqual(participants?.mode, .twoVsTwo)
        XCTAssertEqual(participants?.teamA.map(\.id), ["1", "2"])
        XCTAssertEqual(participants?.teamB.map(\.id), ["3", "4"])
    }

    func testPrepareRandomPoolDrawsTwoIDsPerSlotAndOnlyOnce() async {
        let ids = (1...65).map(String.init)
        let roster = ids.map { makeHero(id: $0) }
        let catalog = SpyCatalogRepository()
        let remote = StubHeroRepository(outcome: .success(roster))
        let viewModel = makeViewModel(
            mode: .threeVsThree,
            catalog: catalog,
            preload: LoadHeroesByIDsUseCase(catalog: catalog, remote: remote),
            characterIDs: StubCharacterIDProvider(ids: ids)
        )

        viewModel.prepareRandomPool()
        await waitFor { catalog.storedIDs().count == 6 }

        let stored = catalog.storedIDs()
        XCTAssertEqual(stored.count, 6, "3v3 precarga exactamente 6 IDs sorteados")
        XCTAssertEqual(
            stored.sorted(),
            Set((1...6).map(String.init)).sorted(),
            "El picker secuencial toma los primeros IDs del índice"
        )

        viewModel.prepareRandomPool()
        await settle()

        let upserted = catalog.upsertedIDs()
        XCTAssertEqual(upserted.count, 6, "La precarga no debe ejecutarse dos veces")
    }

    func testPrepareRandomPoolSizeFollowsMode() async {
        let cases: [(CombatMode, Int)] = [(.oneVsOne, 2), (.twoVsTwo, 4), (.threeVsThree, 6)]

        for (mode, expectedCount) in cases {
            let ids = (1...65).map(String.init)
            let roster = ids.map { makeHero(id: $0) }
            let catalog = SpyCatalogRepository()
            let viewModel = makeViewModel(
                mode: mode,
                catalog: catalog,
                preload: LoadHeroesByIDsUseCase(
                    catalog: catalog,
                    remote: StubHeroRepository(outcome: .success(roster))
                ),
                characterIDs: StubCharacterIDProvider(ids: ids)
            )

            viewModel.prepareRandomPool()
            await waitFor { catalog.storedIDs().count == expectedCount }

            let stored = catalog.storedIDs()
            XCTAssertEqual(stored.count, expectedCount, "El pool de \(mode.rawValue) debe tener \(expectedCount) héroes")
        }
    }

    func testFillRandomConsumesPreloadedPoolBeforeCatalog() async {
        let roster = (1...10).map { makeHero(id: String($0)) }
        let loadCatalog = SpyCatalogRepository()
        let viewModel = makeViewModel(
            mode: .oneVsOne,
            catalog: FailingCatalog(),
            preload: LoadHeroesByIDsUseCase(
                catalog: loadCatalog,
                remote: StubHeroRepository(outcome: .success(roster))
            ),
            characterIDs: StubCharacterIDProvider(ids: roster.map(\.id))
        )

        viewModel.prepareRandomPool()
        await waitFor { loadCatalog.storedIDs().count == 2 }
        // The catalog only signals the upsert; the pool append settles on
        // the main actor right after, so give it a beat before consuming.
        await settle()

        viewModel.fillRandom(side: .teamA, slot: 0)

        XCTAssertEqual(viewModel.hero(in: 0, side: .teamA)?.id, "1", "El pool se consume en orden de sorteo")
        XCTAssertNil(viewModel.busySlot, "El pool resuelve el hueco al instante, sin catálogo")
        XCTAssertNil(viewModel.message)
    }

    func testFillRandomSkipsPoolHeroAlreadyInTeam() async {
        let roster = (1...10).map { makeHero(id: String($0)) }
        let loadCatalog = SpyCatalogRepository()
        let viewModel = makeViewModel(
            mode: .twoVsTwo,
            catalog: FailingCatalog(),
            preload: LoadHeroesByIDsUseCase(
                catalog: loadCatalog,
                remote: StubHeroRepository(outcome: .success(roster))
            ),
            characterIDs: StubCharacterIDProvider(ids: roster.map(\.id))
        )

        viewModel.prepareRandomPool()
        await waitFor { loadCatalog.storedIDs().count == 4 }
        // Same as above: let the main-actor pool append settle.
        await settle()

        // Hero 1 was picked by hand for Team A: the pool skips it.
        viewModel.assign(makeHero(id: "1"), to: .teamA, slot: 0)

        viewModel.fillRandom(side: .teamA, slot: 1)

        XCTAssertEqual(viewModel.hero(in: 1, side: .teamA)?.id, "2")
        XCTAssertNil(viewModel.message)
    }

    func testFillRandomDrawsFreshIDWhenPoolIsExhausted() async {
        let ids = (1...10).map(String.init)
        let roster = ids.map { makeHero(id: $0) }
        let catalog = SpyCatalogRepository()
        let viewModel = makeViewModel(
            mode: .oneVsOne,
            catalog: catalog,
            preload: LoadHeroesByIDsUseCase(
                catalog: catalog,
                remote: StubHeroRepository(outcome: .success(roster))
            ),
            characterIDs: StubCharacterIDProvider(ids: ids)
        )

        viewModel.prepareRandomPool()
        await waitFor { catalog.storedIDs().count == 2 }
        // Same as above: let the main-actor pool append settle.
        await settle()

        // Exhaust the pool by consuming it and then clearing the slot.
        for expectedID in ["1", "2"] {
            viewModel.fillRandom(side: .teamA, slot: 0)
            XCTAssertEqual(viewModel.hero(in: 0, side: .teamA)?.id, expectedID)
            viewModel.clear(side: .teamA, slot: 0)
        }

        // Pool exhausted: on-demand random draw that excludes already drawn IDs.
        viewModel.fillRandom(side: .teamA, slot: 0)
        await waitFor { viewModel.hero(in: 0, side: .teamA)?.id == "3" }

        XCTAssertEqual(viewModel.hero(in: 0, side: .teamA)?.id, "3")
        XCTAssertNil(viewModel.message)
        XCTAssertNil(viewModel.busySlot)

        // Nor does it repeat the ID just drawn on demand.
        viewModel.clear(side: .teamA, slot: 0)
        viewModel.fillRandom(side: .teamA, slot: 0)
        await waitFor { viewModel.hero(in: 0, side: .teamA)?.id == "4" }

        XCTAssertEqual(viewModel.hero(in: 0, side: .teamA)?.id, "4", "Los IDs ya sorteados nunca se repiten")
    }

    func testFillRandomFillsOnlyRequestedSlotExcludingOwnTeam() async {
        let roster = makeRoster(count: 6)
        let viewModel = makeViewModel(
            mode: .twoVsTwo,
            catalog: SpyCatalogRepository(heroes: roster)
        )

        viewModel.assign(roster[0], to: .teamA, slot: 0)
        viewModel.fillRandom(side: .teamA, slot: 1)
        await waitFor { viewModel.hero(in: 1, side: .teamA) != nil }

        XCTAssertEqual(viewModel.hero(in: 1, side: .teamA)?.id, "2")
        XCTAssertNil(viewModel.message)
        XCTAssertNil(viewModel.busySlot)
    }

    func testFillRandomWithEmptyCatalogPublishesNoHeroes() async {
        let viewModel = makeViewModel(mode: .oneVsOne, catalog: SpyCatalogRepository())

        viewModel.fillRandom(side: .teamA, slot: 0)
        await waitFor { viewModel.message == .noHeroesAvailable }

        XCTAssertNil(viewModel.hero(in: 0, side: .teamA))
        XCTAssertNil(viewModel.busySlot)
    }

    func testFillRandomTransportFailurePublishesNoHeroes() async {
        let viewModel = makeViewModel(mode: .oneVsOne, catalog: FailingCatalog())

        viewModel.fillRandom(side: .teamA, slot: 0)
        await waitFor { viewModel.message == .noHeroesAvailable }

        XCTAssertNil(viewModel.hero(in: 0, side: .teamA))
        XCTAssertNil(viewModel.busySlot)
    }

    func testCancelDuringFillRandomDoesNotAssign() async {
        let catalog = GatedCatalog()
        let viewModel = makeViewModel(mode: .oneVsOne, catalog: catalog)

        viewModel.fillRandom(side: .teamA, slot: 0)
        await waitFor { viewModel.busySlot != nil }

        viewModel.cancelActiveWork()

        await catalog.failAllWithCancellation()
        await settle()

        XCTAssertNil(viewModel.hero(in: 0, side: .teamA))
        XCTAssertNil(viewModel.message)
        XCTAssertNil(viewModel.busySlot)
    }

    func testCancelDuringPoolPreloadDiscardsWork() async {
        let ids = (1...10).map(String.init)
        let roster = ids.map { makeHero(id: $0) }
        let catalog = SpyCatalogRepository()
        let remote = GatedHeroRepository(heroes: roster)
        let viewModel = makeViewModel(
            mode: .oneVsOne,
            catalog: catalog,
            preload: LoadHeroesByIDsUseCase(catalog: catalog, remote: remote),
            characterIDs: StubCharacterIDProvider(ids: ids)
        )

        viewModel.prepareRandomPool()
        await waitFor { remote.pendingCount() == 2 }

        viewModel.cancelActiveWork()

        remote.completeAllPending()
        await settle()

        XCTAssertNil(viewModel.hero(in: 0, side: .teamA))
        XCTAssertNil(viewModel.hero(in: 0, side: .teamB))
        XCTAssertNil(viewModel.message)
        XCTAssertNil(viewModel.busySlot)

        let stored = catalog.storedIDs()
        XCTAssertTrue(stored.isEmpty, "Una precarga cancelada no debe persistir la tirada")
    }

    // MARK: - Helpers

    @MainActor
    private func makeViewModel(
        mode: CombatMode,
        catalog: (any HeroCatalogRepository)? = nil,
        preload: LoadHeroesByIDsUseCase? = nil,
        characterIDs: (any CharacterIDProviding)? = nil,
        idPicker: (any RandomIDPicker)? = nil
    ) -> TeamSelectionViewModel {
        // Default constructions happen in the body: actors cannot appear
        // as default arguments.
        let resolvedCatalog = catalog ?? SpyCatalogRepository()
        let resolvedPreload = preload ?? LoadHeroesByIDsUseCase(
            catalog: InMemoryHeroCatalogRepository(),
            remote: StubHeroRepository(outcome: .success([]))
        )
        let resolvedIDs = characterIDs ?? StubCharacterIDProvider(ids: [])
        let resolvedPicker = idPicker ?? SequentialIDPicker()

        return TeamSelectionViewModel(
            mode: mode,
            selectHero: SelectHeroUseCase(),
            generateRandomHero: GenerateRandomHeroUseCase(
                catalog: resolvedCatalog,
                picker: FirstAvailablePicker()
            ),
            drawRandomHeroes: DrawRandomHeroesUseCase(
                characterIDs: resolvedIDs,
                loadHeroes: resolvedPreload,
                picker: resolvedPicker
            ),
            buildBattleParticipants: BuildBattleParticipantsUseCase()
        )
    }

    private func waitFor(
        timeout: Int = 2,
        _ condition: @escaping () async -> Bool
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
        for _ in 0..<60 {
            await Task.yield()
        }
    }

    private func makeHero(id: String) -> Hero {
        Hero(id: id, name: "Hero \(id)")
    }

    private func makeRoster(count: Int) -> [Hero] {
        (1...count).map { makeHero(id: String($0)) }
    }
}

/// Deterministic picker: returns the first hero not excluded.
private struct FirstAvailablePicker: RandomHeroPicker {
    func pick(from heroes: [Hero], excluding heroIDs: Set<String>) -> Hero? {
        heroes.first { !heroIDs.contains($0.id) }
    }
}

/// Deterministic ID picker: returns the first available IDs in order.
private struct SequentialIDPicker: RandomIDPicker {
    func pickIDs(from ids: [String], excluding excludedIDs: Set<String>, count: Int) -> [String] {
        Array(ids.filter { !excludedIDs.contains($0) }.prefix(count))
    }
}

/// Catalog whose `allHeroes` always fails with a transport error.
private struct FailingCatalog: HeroCatalogRepository {
    func allHeroes() async throws -> [Hero] {
        throw HeroRepositoryError.transport
    }

    func hero(id: String) async throws -> Hero? { nil }

    func heroes(ids: [String]) async throws -> [Hero] { [] }

    func upsert(_ heroes: [Hero]) async throws {}
}

/// Catalog that suspends `allHeroes` until the test releases it.
private actor GatedCatalog: HeroCatalogRepository {
    private var continuations: [CheckedContinuation<[Hero], Error>] = []

    func allHeroes() async throws -> [Hero] {
        try await withCheckedThrowingContinuation { continuation in
            continuations.append(continuation)
        }
    }

    func failAllWithCancellation() {
        let pending = continuations
        continuations = []
        for continuation in pending {
            continuation.resume(throwing: CancellationError())
        }
    }

    func hero(id: String) async throws -> Hero? { nil }

    func heroes(ids: [String]) async throws -> [Hero] { [] }

    func upsert(_ heroes: [Hero]) async throws {}
}

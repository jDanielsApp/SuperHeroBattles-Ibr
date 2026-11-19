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

    func testPreloadFetchesOnlyTheFirstPageOnce() async {
        let ids = (1...65).map(String.init)
        let roster = ids.map { makeHero(id: $0) }
        let catalog = SpyCatalogRepository()
        let remote = StubHeroRepository(outcome: .success(roster))
        let viewModel = makeViewModel(
            mode: .oneVsOne,
            catalog: catalog,
            preload: LoadHeroesByIDsUseCase(catalog: catalog, remote: remote),
            characterIDs: StubCharacterIDProvider(ids: ids)
        )

        viewModel.loadCatalogIfNeeded()
        await waitFor { await catalog.storedIDs().count == 30 }

        let stored = await catalog.storedIDs()
        XCTAssertEqual(stored.count, 30)
        XCTAssertEqual(stored.sorted(), Set(ids.prefix(30)).sorted())

        viewModel.loadCatalogIfNeeded()
        await settle()

        let upserted = await catalog.upsertedIDs()
        XCTAssertEqual(upserted.count, 30, "La precarga no debe ejecutarse dos veces")
    }

    // MARK: - Helpers

    @MainActor
    private func makeViewModel(
        mode: CombatMode,
        catalog: (any HeroCatalogRepository)? = nil,
        preload: LoadHeroesByIDsUseCase? = nil,
        characterIDs: (any CharacterIDProviding)? = nil
    ) -> TeamSelectionViewModel {
        // Las construcciones por defecto se hacen en el cuerpo: los actores
        // no pueden aparecer como argumentos por defecto.
        let resolvedCatalog = catalog ?? SpyCatalogRepository()
        let resolvedPreload = preload ?? LoadHeroesByIDsUseCase(
            catalog: InMemoryHeroCatalogRepository(),
            remote: StubHeroRepository(outcome: .success([]))
        )
        let resolvedIDs = characterIDs ?? StubCharacterIDProvider(ids: [])

        return TeamSelectionViewModel(
            mode: mode,
            selectHero: SelectHeroUseCase(),
            generateRandomHero: GenerateRandomHeroUseCase(
                catalog: resolvedCatalog,
                picker: FirstAvailablePicker()
            ),
            buildBattleParticipants: BuildBattleParticipantsUseCase(),
            preloadHeroes: resolvedPreload,
            characterIDs: resolvedIDs
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

/// Picker determinista: devuelve el primer héroe no excluido.
private struct FirstAvailablePicker: RandomHeroPicker {
    func pick(from heroes: [Hero], excluding heroIDs: Set<String>) -> Hero? {
        heroes.first { !heroIDs.contains($0.id) }
    }
}

/// Catálogo cuyo `allHeroes` siempre falla con error de transporte.
private struct FailingCatalog: HeroCatalogRepository {
    func allHeroes() async throws -> [Hero] {
        throw HeroRepositoryError.transport
    }

    func hero(id: String) async throws -> Hero? { nil }

    func heroes(ids: [String]) async throws -> [Hero] { [] }

    func upsert(_ heroes: [Hero]) async throws {}
}

/// Catálogo que suspende `allHeroes` hasta que el test lo libera.
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

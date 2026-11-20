import XCTest
@testable import SuperHeroBattle

@MainActor
final class CombatViewModelTests: XCTestCase {
    func testNarrationLoadsAndPublishesItsSource() async {
        let narrative = CombatNarrative(text: "Narración simulada", source: .foundationModels)
        let service = MockNarrationService(behavior: .narrative(narrative))
        let viewModel = makeViewModel(service: service, language: .spanish)

        XCTAssertTrue(viewModel.isGeneratingNarration || viewModel.narration == nil)
        await viewModel.loadNarration()

        XCTAssertEqual(viewModel.narration?.source, .foundationModels)
        XCTAssertEqual(viewModel.narration?.text, "Narración simulada")
        XCTAssertFalse(viewModel.isGeneratingNarration)
        let recordedLanguage = await service.recordedLanguage()
        XCTAssertEqual(recordedLanguage, .spanish)
    }

    func testTemplateFallbackIsPublishedWhenServiceFails() async {
        let service = MockNarrationService(behavior: .failure)
        let viewModel = makeViewModel(service: service, language: .english)

        await viewModel.loadNarration()

        XCTAssertEqual(viewModel.narration?.source, .template)
        XCTAssertFalse(viewModel.narration?.text.isEmpty ?? true)
        XCTAssertFalse(viewModel.isGeneratingNarration)
    }

    func testServiceCancellationPublishesNothing() async {
        let service = MockNarrationService(behavior: .cancellation)
        let viewModel = makeViewModel(service: service, language: .english)

        await viewModel.loadNarration()

        XCTAssertNil(viewModel.narration)
        XCTAssertFalse(viewModel.isGeneratingNarration)
    }

    func testNarrationNeverAltersTheCombatResult() async {
        let narrative = CombatNarrative(text: "IA narrativa", source: .foundationModels)
        let service = MockNarrationService(behavior: .narrative(narrative))
        let viewModel = makeViewModel(service: service, language: .spanish)

        let originalOutcome = viewModel.result.outcome
        let originalTotals = (viewModel.result.teamA.totalScore, viewModel.result.teamB.totalScore)

        await viewModel.loadNarration()

        XCTAssertEqual(viewModel.result.outcome, originalOutcome)
        XCTAssertEqual(viewModel.result.teamA.totalScore, originalTotals.0)
        XCTAssertEqual(viewModel.result.teamB.totalScore, originalTotals.1)
    }

    func testNarrationPublicationControlsTheSuspenseReveal() async {
        let narrative = CombatNarrative(text: "Narración simulada", source: .foundationModels)
        let service = MockNarrationService(behavior: .narrative(narrative))
        let viewModel = makeViewModel(service: service, language: .spanish)

        // Antes de publicar la narración el combate queda en suspense.
        XCTAssertFalse(viewModel.isNarrationPublished)
        XCTAssertFalse(viewModel.canSave)

        await viewModel.loadNarration()

        // Publicada la narración, ganador y puntuaciones se revelan.
        XCTAssertTrue(viewModel.isNarrationPublished)
        XCTAssertTrue(viewModel.canSave)
    }

    func testFailedNarrationKeepsTheSuspenseUnrevealed() async {
        let service = MockNarrationService(behavior: .cancellation)
        let viewModel = makeViewModel(service: service, language: .spanish)

        await viewModel.loadNarration()

        XCTAssertNil(viewModel.narration)
        XCTAssertFalse(viewModel.isNarrationPublished)
        XCTAssertFalse(viewModel.canSave)
    }

    func testNarrationIsGeneratedOnlyOnce() async {
        let narrative = CombatNarrative(text: "Narración simulada", source: .foundationModels)
        let service = MockNarrationService(behavior: .narrative(narrative))
        let viewModel = makeViewModel(service: service, language: .english)

        await viewModel.loadNarration()
        await viewModel.loadNarration()

        let calls = await service.callCount()
        XCTAssertEqual(calls, 1)
    }

    func testExplicitSavePersistsTheCombatRecord() async {
        let narrative = CombatNarrative(text: "Narración simulada", source: .foundationModels)
        let service = MockNarrationService(behavior: .narrative(narrative))
        let history = InMemoryCombatHistoryRepository()
        let clock = FakeTimeProvider(now: Date(timeIntervalSince1970: 1_234_567))
        var savedCallbacks = 0
        let viewModel = makeViewModel(
            service: service,
            language: .spanish,
            history: history,
            clock: clock,
            onSaved: { savedCallbacks += 1 }
        )

        await viewModel.loadNarration()
        XCTAssertTrue(viewModel.canSave, "Guardar debe habilitarse con la narración publicada")

        await viewModel.save()

        let records = (try? await history.all()) ?? []
        XCTAssertEqual(records.count, 1)

        let record = records[0]
        XCTAssertEqual(record.date, clock.now)
        XCTAssertEqual(record.mode, .oneVsOne)
        XCTAssertEqual(record.teamA.map(\.name), ["Batman"])
        XCTAssertEqual(record.teamB.map(\.name), ["Joker"])
        XCTAssertEqual(record.outcome, viewModel.result.outcome)
        XCTAssertEqual(record.narration, "Narración simulada")
        XCTAssertEqual(record.narrationSource, .foundationModels)

        XCTAssertEqual(savedCallbacks, 1, "onSaved debe invocarse una sola vez tras guardar")
        XCTAssertTrue(viewModel.isSaved)
        XCTAssertFalse(viewModel.canSave, "No se puede guardar dos veces el mismo combate")
    }

    func testTemplateFallbackCanBeSavedExplicitly() async {
        let service = MockNarrationService(behavior: .failure)
        let history = InMemoryCombatHistoryRepository()
        let viewModel = makeViewModel(service: service, language: .english, history: history)

        await viewModel.loadNarration()
        XCTAssertTrue(viewModel.canSave, "El fallback de plantilla también permite guardar")

        await viewModel.save()

        let records = (try? await history.all()) ?? []
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].narrationSource, .template)
        XCTAssertFalse(records[0].narration.isEmpty)
    }

    func testSaveWithoutNarrationDoesNothing() async {
        let service = MockNarrationService(behavior: .cancellation)
        let history = InMemoryCombatHistoryRepository()
        var savedCallbacks = 0
        let viewModel = makeViewModel(
            service: service,
            language: .english,
            history: history,
            onSaved: { savedCallbacks += 1 }
        )

        await viewModel.loadNarration()
        XCTAssertNil(viewModel.narration)
        XCTAssertFalse(viewModel.canSave, "Sin narración publicada no se puede guardar")

        await viewModel.save()

        let records = (try? await history.all()) ?? []
        XCTAssertTrue(records.isEmpty, "Guardar sin narración no debe historificar nada")
        XCTAssertEqual(savedCallbacks, 0)
    }

    func testFailedSaveAllowsRetryWithoutNavigating() async {
        let narrative = CombatNarrative(text: "Narración simulada", source: .foundationModels)
        let service = MockNarrationService(behavior: .narrative(narrative))
        let history = FailingSaveHistoryRepository()
        var savedCallbacks = 0
        let viewModel = makeViewModel(
            service: service,
            language: .english,
            history: history,
            onSaved: { savedCallbacks += 1 }
        )

        await viewModel.loadNarration()

        await viewModel.save()

        XCTAssertFalse(viewModel.isSaved, "Un fallo de Realm no marca el combate como guardado")
        XCTAssertTrue(viewModel.canSave, "El usuario puede reintentar tras un fallo")
        XCTAssertEqual(savedCallbacks, 0, "Un fallo de guardado no navega a Home")
    }

    // MARK: - Helpers

    private func makeViewModel(
        service: MockNarrationService,
        language: NarrationLanguage,
        history: any CombatHistoryRepository = InMemoryCombatHistoryRepository(),
        clock: any TimeProvider = SystemTimeProvider(),
        onSaved: (@MainActor () -> Void)? = nil
    ) -> CombatViewModel {
        CombatViewModel(
            participants: makeParticipants(),
            resolveCombat: ResolveCombatUseCase(
                engine: CombatEngine(luckProvider: SequenceLuckProvider([40, 20]))
            ),
            generateNarration: GenerateCombatNarrationUseCase(
                service: service,
                fallback: TemplateNarrationService()
            ),
            narrationLanguage: language,
            saveCombatHistory: SaveCombatHistoryUseCase(repository: history),
            timeProvider: clock,
            onSaved: onSaved
        )
    }

    private func makeParticipants() -> BattleParticipants {
        BattleParticipants(
            mode: .oneVsOne,
            teamA: [Hero(id: "1", name: "Batman")],
            teamB: [Hero(id: "2", name: "Joker")]
        )
    }
}

/// Repositorio cuyo `save` siempre falla: cubre el reintento silencioso.
private struct FailingSaveHistoryRepository: CombatHistoryRepository {
    func save(_ record: CombatRecord) async throws {
        throw HeroRepositoryError.transport
    }

    func all() async throws -> [CombatRecord] { [] }

    func record(id: UUID) async throws -> CombatRecord? { nil }

    func delete(id: UUID) async throws {}

    func deleteAll() async throws {}
}

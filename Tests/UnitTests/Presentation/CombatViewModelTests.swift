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

    func testNarrationIsGeneratedOnlyOnce() async {
        let narrative = CombatNarrative(text: "Narración simulada", source: .foundationModels)
        let service = MockNarrationService(behavior: .narrative(narrative))
        let viewModel = makeViewModel(service: service, language: .english)

        await viewModel.loadNarration()
        await viewModel.loadNarration()

        let calls = await service.callCount()
        XCTAssertEqual(calls, 1)
    }

    // MARK: - Helpers

    private func makeViewModel(
        service: MockNarrationService,
        language: NarrationLanguage
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
            narrationLanguage: language
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

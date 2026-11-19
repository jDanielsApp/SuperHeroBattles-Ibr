import XCTest
@testable import SuperHeroBattle

final class GenerateCombatNarrationUseCaseTests: XCTestCase {
    func testAvailableServiceNarrativeIsPassedThrough() async throws {
        let narrative = CombatNarrative(text: "Épica batalla", source: .foundationModels)
        let service = MockNarrationService(behavior: .narrative(narrative))
        let useCase = makeUseCase(service: service)

        let result = try await useCase.execute(
            result: makeResult(),
            participants: makeParticipants(),
            language: .spanish
        )

        XCTAssertEqual(result.source, .foundationModels)
        let calls = await service.callCount()
        XCTAssertEqual(calls, 1)
    }

    func testUnavailableServiceFallsBackToTemplate() async throws {
        let service = MockNarrationService(
            availability: .unavailable(reason: "appleIntelligenceNotEnabled"),
            behavior: .narrative(CombatNarrative(text: "IA", source: .foundationModels))
        )
        let useCase = makeUseCase(service: service)

        let result = try await useCase.execute(
            result: makeResult(),
            participants: makeParticipants(),
            language: .english
        )

        XCTAssertEqual(result.source, .template)
        XCTAssertFalse(result.text.isEmpty)
        let calls = await service.callCount()
        XCTAssertEqual(calls, 0, "El servicio de IA no debe invocarse si no está disponible")
    }

    func testServiceFailureFallsBackToTemplate() async throws {
        let service = MockNarrationService(behavior: .failure)
        let useCase = makeUseCase(service: service)

        let result = try await useCase.execute(
            result: makeResult(),
            participants: makeParticipants(),
            language: .english
        )

        XCTAssertEqual(result.source, .template)
        XCTAssertFalse(result.text.isEmpty)
    }

    func testCancellationPropagatesWithoutFallback() async {
        let service = MockNarrationService(behavior: .cancellation)
        let useCase = makeUseCase(service: service)

        do {
            _ = try await useCase.execute(
                result: makeResult(),
                participants: makeParticipants(),
                language: .english
            )
            XCTFail("Se esperaba cancelación")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }

        let calls = await service.callCount()
        XCTAssertEqual(calls, 1, "La cancelación no debe sustituirse por la plantilla")
    }

    func testCancelledTaskThrowsBeforeAnyGeneration() async {
        let service = MockNarrationService(
            behavior: .narrative(CombatNarrative(text: "IA", source: .foundationModels))
        )
        let useCase = makeUseCase(service: service)
        let result = makeResult()
        let participants = makeParticipants()

        let task = Task {
            try await useCase.execute(
                result: result,
                participants: participants,
                language: .english
            )
        }
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Se esperaba cancelación")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }

        let calls = await service.callCount()
        XCTAssertEqual(calls, 0, "Una tarea cancelada no debe llegar a generar")
    }

    func testPromptContainsDomainDataAndNoConfiguration() {
        let prompt = NarrationPrompts.combatPrompt(
            result: makeResult(),
            participants: makeParticipants(),
            language: .spanish
        )

        XCTAssertTrue(prompt.contains("Batman"))
        XCTAssertTrue(prompt.contains("Joker"))
        XCTAssertTrue(prompt.contains("Team A"))
        XCTAssertTrue(prompt.contains("winner is Team A"))
        XCTAssertFalse(prompt.contains("SUPERHERO_API_TOKEN"))
        XCTAssertFalse(prompt.contains("SuperHeroAPIToken"))
    }

    func testInstructionsAreVersionedAndForbidChangingTheResult() {
        let instructions = NarrationPrompts.instructions(language: .spanish)

        XCTAssertEqual(NarrationPrompts.version, 1)
        XCTAssertTrue(instructions.contains("prompt version: 1"))
        XCTAssertTrue(instructions.contains("Never change the winner"))
        XCTAssertTrue(instructions.contains("Write in Spanish"))
    }

    func testDrawPromptDeclaresDraw() {
        let engine = CombatEngine(luckProvider: SequenceLuckProvider([7, 7]))
        let hero = Hero(id: "1", name: "Batman")
        let participants = BattleParticipants(mode: .oneVsOne, teamA: [hero], teamB: [hero])
        let result = engine.resolve(participants)

        let prompt = NarrationPrompts.combatPrompt(
            result: result,
            participants: participants,
            language: .english
        )

        XCTAssertTrue(prompt.contains("The combat is a draw"))
    }

    // MARK: - Helpers

    private func makeUseCase(
        service: MockNarrationService
    ) -> GenerateCombatNarrationUseCase {
        GenerateCombatNarrationUseCase(
            service: service,
            fallback: TemplateNarrationService()
        )
    }

    private func makeParticipants() -> BattleParticipants {
        BattleParticipants(
            mode: .oneVsOne,
            teamA: [Hero(id: "1", name: "Batman")],
            teamB: [Hero(id: "2", name: "Joker")]
        )
    }

    private func makeResult() -> CombatResult {
        CombatEngine(luckProvider: SequenceLuckProvider([40, 20]))
            .resolve(makeParticipants())
    }
}

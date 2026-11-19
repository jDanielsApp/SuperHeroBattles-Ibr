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
            context: makeContext(),
            language: .spanish
        )

        XCTAssertTrue(prompt.contains("Batman"))
        XCTAssertTrue(prompt.contains("Joker"))
        XCTAssertTrue(prompt.contains("Team A: Batman"))
        XCTAssertTrue(prompt.contains("Team B: Joker"))
        XCTAssertTrue(prompt.contains("[TEAM A] Batman"))
        XCTAssertTrue(prompt.contains("[TEAM B] Joker"))
        XCTAssertTrue(prompt.contains("Point difference"))
        XCTAssertTrue(prompt.contains("The winner is Team A"))
        XCTAssertFalse(prompt.contains("SUPERHERO_API_TOKEN"))
        XCTAssertFalse(prompt.contains("SuperHeroAPIToken"))
    }

    func testInstructionsAreVersionedAndForbidChangingTheResult() {
        let instructions = NarrationPrompts.instructions(language: .spanish)

        XCTAssertEqual(NarrationPrompts.version, 2)
        XCTAssertTrue(instructions.contains("prompt version: 2"))
        XCTAssertTrue(instructions.contains("Never change the winner"))
        XCTAssertTrue(instructions.contains("Write in Spanish"))
        XCTAssertTrue(instructions.contains("characteristic flourish"), "Debe permitirse un detalle del lore conocido")
        XCTAssertTrue(instructions.contains("batarang"), "Debe incluir el ejemplo de estilo localizado")
    }

    func testPromptMarksClearVictoryWhenGapIsAtLeastThirty() {
        // 100 + 7 frente a 70 + 7: diferencia exacta de 30.
        let clear = NarrationPrompts.combatPrompt(
            context: makeContext(intelligenceA: 100, intelligenceB: 70, luck: [7, 7]),
            language: .english
        )
        // 99 + 7 frente a 70 + 7: diferencia 29.
        let close = NarrationPrompts.combatPrompt(
            context: makeContext(intelligenceA: 99, intelligenceB: 70, luck: [7, 7]),
            language: .english
        )

        XCTAssertTrue(clear.contains("the victory is CLEAR"))
        XCTAssertTrue(close.contains("the victory is CLOSE"))
    }

    func testPromptLabelsBothSidesWhenSameHeroRepeats() {
        let hero = Hero(id: "1", name: "Batman")
        let participants = BattleParticipants(mode: .oneVsOne, teamA: [hero], teamB: [hero])
        let result = CombatEngine(luckProvider: SequenceLuckProvider([7, 7]))
            .resolve(participants)

        let prompt = NarrationPrompts.combatPrompt(
            context: NarrationContext(result: result, participants: participants),
            language: .english
        )

        XCTAssertTrue(prompt.contains("[TEAM A] Batman"))
        XCTAssertTrue(prompt.contains("[TEAM B] Batman"))
    }

    func testDrawPromptDeclaresDraw() {
        let hero = Hero(id: "1", name: "Batman", powerStats: PowerStats(intelligence: 50))
        let participants = BattleParticipants(mode: .oneVsOne, teamA: [hero], teamB: [hero])
        let result = CombatEngine(luckProvider: SequenceLuckProvider([7, 7]))
            .resolve(participants)

        let prompt = NarrationPrompts.combatPrompt(
            context: NarrationContext(result: result, participants: participants),
            language: .english
        )

        XCTAssertTrue(prompt.contains("the combat is a DRAW with no winner"))
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

    private func makeContext(
        intelligenceA: Int = 100,
        intelligenceB: Int = 70,
        luck: [Int] = [40, 20]
    ) -> NarrationContext {
        let participants = makeParticipants(intelligenceA: intelligenceA, intelligenceB: intelligenceB)
        let result = CombatEngine(luckProvider: SequenceLuckProvider(luck))
            .resolve(participants)

        return NarrationContext(result: result, participants: participants)
    }

    private func makeParticipants(
        intelligenceA: Int = 100,
        intelligenceB: Int = 70
    ) -> BattleParticipants {
        BattleParticipants(
            mode: .oneVsOne,
            teamA: [
                Hero(
                    id: "1",
                    name: "Batman",
                    powerStats: PowerStats(intelligence: intelligenceA)
                )
            ],
            teamB: [
                Hero(
                    id: "2",
                    name: "Joker",
                    powerStats: PowerStats(intelligence: intelligenceB)
                )
            ]
        )
    }

    private func makeResult() -> CombatResult {
        CombatEngine(luckProvider: SequenceLuckProvider([40, 20]))
            .resolve(makeParticipants())
    }
}

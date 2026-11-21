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

    func testGuardrailFailureFallsBackToTemplate() async throws {
        let service = MockNarrationService(behavior: .guardrail)
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
        XCTAssertTrue(prompt.contains("Equipo A: Batman"))
        XCTAssertTrue(prompt.contains("Equipo B: Joker"))
        XCTAssertTrue(prompt.contains("[Equipo A] Batman"))
        XCTAssertTrue(prompt.contains("[Equipo B] Joker"))
        XCTAssertTrue(prompt.contains("Diferencia de puntos"))
        XCTAssertTrue(prompt.contains("El ganador es Equipo A"))
        XCTAssertFalse(prompt.contains("SUPERHERO_API_TOKEN"))
        XCTAssertFalse(prompt.contains("SuperHeroAPIToken"))
    }

    func testEnglishPromptKeepsEnglishLabels() {
        let prompt = NarrationPrompts.combatPrompt(
            context: makeContext(),
            language: .english
        )

        XCTAssertTrue(prompt.contains("Team A: Batman"))
        XCTAssertTrue(prompt.contains("[Team B] Joker"))
        XCTAssertTrue(prompt.contains("The winner is Team A"))
        XCTAssertTrue(prompt.contains("Point difference"))
    }

    func testPromptNumbersUseTheNarrationLanguageDecimalSeparator() {
        // Five known stats averaging 92.8: the fractional base forces a
        // decimal separator into the prompt.
        let fractional = Hero(
            id: "1",
            name: "Batman",
            powerStats: PowerStats(
                intelligence: 100,
                strength: 100,
                speed: 100,
                durability: 100,
                power: 64
            )
        )
        let participants = BattleParticipants(
            mode: .oneVsOne,
            teamA: [fractional],
            teamB: [fractional]
        )
        let result = CombatEngine(luckProvider: SequenceLuckProvider([7, 7]))
            .resolve(participants)

        let english = NarrationPrompts.combatPrompt(
            context: NarrationContext(result: result, participants: participants),
            language: .english
        )
        let spanish = NarrationPrompts.combatPrompt(
            context: NarrationContext(result: result, participants: participants),
            language: .spanish
        )

        XCTAssertTrue(
            english.contains("computed base 92.8"),
            "El prompt en inglés debe usar el punto decimal"
        )
        XCTAssertTrue(
            spanish.contains("computed base 92,8"),
            "El prompt en español debe usar la coma decimal"
        )
        XCTAssertFalse(
            english.contains("92,8"),
            "El prompt en inglés no debe mezclar la coma decimal"
        )
        XCTAssertFalse(
            spanish.contains("92.8"),
            "El prompt en español no debe mezclar el punto decimal"
        )
    }

    func testInstructionsAreVersionedAndForbidChangingTheResult() {
        let instructions = NarrationPrompts.instructions(language: .spanish, safeMode: false)

        XCTAssertEqual(NarrationPrompts.version, 4)
        XCTAssertTrue(instructions.contains("prompt version: 4"))
        XCTAssertTrue(instructions.contains("Never change the winner"))
        XCTAssertTrue(instructions.contains("Write in Spanish"))
        XCTAssertTrue(instructions.contains("characteristic flourish"), "Debe permitirse un detalle del lore conocido")
        XCTAssertTrue(instructions.contains("batarang"), "Debe incluir el ejemplo de estilo localizado")
    }

    func testPromptMarksClearVictoryWhenGapIsAtLeastThirty() {
        // 100 + 7 versus 70 + 7: exactly a 30-point difference.
        let clear = NarrationPrompts.combatPrompt(
            context: makeContext(intelligenceA: 100, intelligenceB: 70, luck: [7, 7]),
            language: .english
        )
        // 99 + 7 versus 70 + 7: a 29-point difference.
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

        XCTAssertTrue(prompt.contains("[Team A] Batman"))
        XCTAssertTrue(prompt.contains("[Team B] Batman"))
    }

    func testInstructionsForbidIntraTeamFighting() {
        let creative = NarrationPrompts.instructions(language: .english, safeMode: false)
        let safe = NarrationPrompts.instructions(language: .english, safeMode: true)

        XCTAssertTrue(
            creative.contains("NEVER attack each other"),
            "El intento creativo debe prohibir que los compañeros se peleen"
        )
        XCTAssertTrue(
            safe.contains("NEVER attack each other"),
            "El reintento safe debe prohibir que los compañeros se peleen"
        )
        XCTAssertTrue(creative.contains("only between heroes from different teams"))
        XCTAssertTrue(safe.contains("only between heroes from different teams"))
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

import XCTest
@testable import SuperHeroBattle

/// Prueba la estrategia de reintento del servicio con el seam inyectable:
/// nunca invoca el modelo real.
final class FoundationModelsNarrationServiceTests: XCTestCase {
    func testRetriesWithSafePromptWhenGuardrailTriggers() async throws {
        let recorder = AttemptRecorder()
        let service = FoundationModelsNarrationService(attempt: { instructions, _, _, _ in
            await recorder.record(instructions: instructions)
            let calls = await recorder.callCount()

            if calls == 1 {
                throw Self.makeGuardrailError()
            }

            return Self.validNarration
        })

        let narrative = try await service.narrate(
            result: Self.makeResult(),
            participants: Self.makeParticipants(),
            language: .english
        )

        XCTAssertEqual(narrative.source, .foundationModels)
        XCTAssertTrue(narrative.text.contains("Team A"))

        let calls = await recorder.callCount()
        XCTAssertEqual(calls, 2, "Debe reintentar exactamente una vez")

        let secondInstructions = await recorder.instructions(at: 1)
        let unwrapped = try XCTUnwrap(secondInstructions)
        XCTAssertTrue(unwrapped.contains("safe mode"))
        XCTAssertTrue(unwrapped.contains("Never describe injuries"))
    }

    func testAttemptTemperaturesMatchCreativeAndSafeModes() async throws {
        let recorder = AttemptRecorder()
        let service = FoundationModelsNarrationService(attempt: { instructions, _, temperature, _ in
            await recorder.record(instructions: instructions, temperature: temperature)
            let calls = await recorder.callCount()

            if calls == 1 {
                throw Self.makeGuardrailError()
            }

            return Self.validNarration
        })

        _ = try await service.narrate(
            result: Self.makeResult(),
            participants: Self.makeParticipants(),
            language: .english
        )

        let firstTemperature = await recorder.temperature(at: 0)
        let secondTemperature = await recorder.temperature(at: 1)

        XCTAssertEqual(firstTemperature, FoundationModelsNarrationService.creativeTemperature)
        XCTAssertEqual(secondTemperature, FoundationModelsNarrationService.safeTemperature)
        XCTAssertEqual(FoundationModelsNarrationService.creativeTemperature, 0.8)
        XCTAssertEqual(FoundationModelsNarrationService.safeTemperature, 0.5)
    }

    func testGuardrailTwiceThrowsTypedGuardrail() async {
        let recorder = AttemptRecorder()
        let service = FoundationModelsNarrationService(attempt: { instructions, _, _, _ in
            await recorder.record(instructions: instructions)
            throw Self.makeGuardrailError()
        })

        do {
            _ = try await service.narrate(
                result: Self.makeResult(),
                participants: Self.makeParticipants(),
                language: .english
            )
            XCTFail("Se esperaba guardrail")
        } catch {
            guard case NarrationError.guardrail = error else {
                return XCTFail("Debería ser guardrail tipado: \(error)")
            }
        }

        let calls = await recorder.callCount()
        XCTAssertEqual(calls, 2, "No debe reintentar más de una vez")
    }

    func testNonGuardrailErrorDoesNotRetry() async {
        let recorder = AttemptRecorder()
        let service = FoundationModelsNarrationService(attempt: { instructions, _, _, _ in
            await recorder.record(instructions: instructions)
            throw NarrationError.timeout
        })

        do {
            _ = try await service.narrate(
                result: Self.makeResult(),
                participants: Self.makeParticipants(),
                language: .english
            )
            XCTFail("Se esperaba timeout")
        } catch {
            XCTAssertEqual(error as? NarrationError, .timeout)
        }

        let calls = await recorder.callCount()
        XCTAssertEqual(calls, 1, "Solo el guardrail reintenta")
    }

    func testCancellationPropagatesWithoutRetry() async {
        let recorder = AttemptRecorder()
        let service = FoundationModelsNarrationService(attempt: { instructions, _, _, _ in
            await recorder.record(instructions: instructions)
            throw CancellationError()
        })

        do {
            _ = try await service.narrate(
                result: Self.makeResult(),
                participants: Self.makeParticipants(),
                language: .english
            )
            XCTFail("Se esperaba cancelación")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }

        let calls = await recorder.callCount()
        XCTAssertEqual(calls, 1)
    }

    // MARK: - Helpers

    private static func makeGuardrailError() -> NSError {
        NSError(domain: "FoundationModels", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "guardrailViolation: may contain sensitive or unsafe content"
        ])
    }

    private static let validNarration = GeneratedNarration(
        opening: "Team A and Team B face off in the arena.",
        exchange: "Dazzling displays of ability from both sides.",
        climax: "Clever strategies decide the outcome.",
        verdict: "The winner is Team A."
    )

    private static func makeParticipants() -> BattleParticipants {
        BattleParticipants(
            mode: .oneVsOne,
            teamA: [Hero(id: "1", name: "Batman", powerStats: PowerStats(intelligence: 100))],
            teamB: [Hero(id: "2", name: "Joker", powerStats: PowerStats(intelligence: 70))]
        )
    }

    private static func makeResult() -> CombatResult {
        CombatEngine(luckProvider: SequenceLuckProvider([40, 20]))
            .resolve(makeParticipants())
    }
}

/// Registro de intentos con aislamiento por actor.
private actor AttemptRecorder {
    private var instructionsHistory: [String] = []
    private var temperatureHistory: [Double] = []

    func record(instructions: String, temperature: Double? = nil) {
        instructionsHistory.append(instructions)
        if let temperature {
            temperatureHistory.append(temperature)
        }
    }

    func callCount() -> Int {
        instructionsHistory.count
    }

    func instructions(at index: Int) -> String? {
        instructionsHistory.indices.contains(index) ? instructionsHistory[index] : nil
    }

    func temperature(at index: Int) -> Double? {
        temperatureHistory.indices.contains(index) ? temperatureHistory[index] : nil
    }
}

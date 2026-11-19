import Foundation
@testable import SuperHeroBattle

/// Servicio de narración controlable para tests: nunca invoca el modelo real.
nonisolated final class MockNarrationService: CombatNarrationService, @unchecked Sendable {
    nonisolated enum Behavior: Sendable {
        case narrative(CombatNarrative)
        case failure
        case guardrail
        case cancellation
    }

    /// Registro aislado en un actor: seguro ante concurrencia.
    private actor Recorder {
        private var count = 0
        private var lastLanguage: NarrationLanguage?

        func record(language: NarrationLanguage) {
            count += 1
            lastLanguage = language
        }

        func callCount() -> Int { count }

        func recordedLanguage() -> NarrationLanguage? { lastLanguage }
    }

    private let availabilityValue: NarrationAvailability
    private let behavior: Behavior
    private let recorder = Recorder()

    init(
        availability: NarrationAvailability = .available,
        behavior: Behavior
    ) {
        self.availabilityValue = availability
        self.behavior = behavior
    }

    var availability: NarrationAvailability {
        get async { availabilityValue }
    }

    func narrate(
        result: CombatResult,
        participants: BattleParticipants,
        language: NarrationLanguage
    ) async throws -> CombatNarrative {
        await recorder.record(language: language)

        switch behavior {
        case .narrative(let narrative):
            return narrative
        case .failure:
            throw NarrationError.emptyResponse
        case .guardrail:
            throw NarrationError.guardrail("guardrailViolation (test)")
        case .cancellation:
            throw CancellationError()
        }
    }

    func callCount() async -> Int {
        await recorder.callCount()
    }

    func recordedLanguage() async -> NarrationLanguage? {
        await recorder.recordedLanguage()
    }
}

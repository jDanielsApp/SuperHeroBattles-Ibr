import Foundation

nonisolated enum NarrationAvailability: Equatable, Sendable {
    case available
    case unavailable(reason: String)
}

nonisolated enum NarrationLanguage: String, Equatable, Sendable {
    case english = "en"
    case spanish = "es"
}

/// Contrato de generación narrativa. La implementación real y el fallback son intercambiables.
nonisolated protocol CombatNarrationService: Sendable {
    var availability: NarrationAvailability { get async }
    func narrate(
        result: CombatResult,
        participants: BattleParticipants,
        language: NarrationLanguage
    ) async throws -> CombatNarrative
}

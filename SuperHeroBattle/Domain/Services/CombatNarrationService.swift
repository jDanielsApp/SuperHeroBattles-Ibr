import Foundation

nonisolated enum NarrationAvailability: Equatable, Sendable {
    case available
    case unavailable(reason: String)
}

nonisolated enum NarrationLanguage: String, Equatable, Sendable {
    case english = "en"
    case spanish = "es"
}

/// Narrative generation contract. The real implementation and the fallback are interchangeable.
nonisolated protocol CombatNarrationService: Sendable {
    var availability: NarrationAvailability { get async }
    func narrate(
        result: CombatResult,
        participants: BattleParticipants,
        language: NarrationLanguage
    ) async throws -> CombatNarrative
}

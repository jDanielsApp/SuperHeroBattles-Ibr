import Foundation

/// Generates the combat narration with AI when available and with the
/// deterministic template otherwise.
///
/// Rules:
/// - The AI only narrates: the `CombatResult` arrives already resolved
///   and immutable.
/// - Cancellation propagates: a cancelled narration is never published
///   nor replaced with the template.
nonisolated struct GenerateCombatNarrationUseCase: Sendable {
    private let service: any CombatNarrationService
    private let fallback: any CombatNarrationService

    init(service: any CombatNarrationService, fallback: any CombatNarrationService) {
        self.service = service
        self.fallback = fallback
    }

    func execute(
        result: CombatResult,
        participants: BattleParticipants,
        language: NarrationLanguage
    ) async throws -> CombatNarrative {
        try Task.checkCancellation()

        if case .unavailable = await service.availability {
            try Task.checkCancellation()
            return try await fallback.narrate(
                result: result,
                participants: participants,
                language: language
            )
        }

        do {
            let narrative = try await service.narrate(
                result: result,
                participants: participants,
                language: language
            )
            try Task.checkCancellation()
            return narrative
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            return try await fallback.narrate(
                result: result,
                participants: participants,
                language: language
            )
        }
    }
}

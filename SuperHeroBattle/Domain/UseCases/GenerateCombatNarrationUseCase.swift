import Foundation

/// Genera la narración del combate con IA cuando está disponible y con la
/// plantilla determinista en cualquier otro caso.
///
/// Reglas de la arquitectura:
/// - La IA solo narra: el `CombatResult` llega ya resuelto e inmutable.
/// - La cancelación se propaga: una narración cancelada nunca se publica
///   ni se sustituye por la plantilla.
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

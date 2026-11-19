import Foundation
import FoundationModels

/// Errores controlados de la narración con IA.
nonisolated enum NarrationError: Error, Equatable, Sendable {
    case emptyResponse
    case timeout
}

/// Narración con Apple Foundation Models.
///
/// La sesión se crea solo tras confirmar la disponibilidad del modelo. La
/// generación se cancela al agotar el timeout: nunca bloquea la interfaz.
nonisolated struct FoundationModelsNarrationService: CombatNarrationService {
    /// Tiempo máximo de generación antes de cancelar y caer a la plantilla.
    static let timeout: TimeInterval = 20

    var availability: NarrationAvailability {
        get async {
            switch SystemLanguageModel.default.availability {
            case .available:
                return .available
            case .unavailable(let reason):
                return .unavailable(reason: String(describing: reason))
            }
        }
    }

    func narrate(
        result: CombatResult,
        participants: BattleParticipants,
        language: NarrationLanguage
    ) async throws -> CombatNarrative {
        let instructions = NarrationPrompts.instructions(language: language)
        let prompt = NarrationPrompts.combatPrompt(
            result: result,
            participants: participants,
            language: language
        )
        let timeout = Self.timeout

        let text: String = try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask {
                let session = LanguageModelSession(instructions: instructions)
                let response = try await session.respond(
                    to: prompt,
                    generating: GeneratedNarration.self
                )
                return response.content.text
            }

            group.addTask {
                try await Task.sleep(for: .seconds(timeout))
                throw NarrationError.timeout
            }

            defer { group.cancelAll() }

            guard let first = try await group.next() else {
                throw NarrationError.timeout
            }
            return first
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NarrationError.emptyResponse
        }

        return CombatNarrative(text: trimmed, source: .foundationModels)
    }
}

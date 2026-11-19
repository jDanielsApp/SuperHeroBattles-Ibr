import Foundation
import FoundationModels

/// Errores controlados de la narración con IA.
nonisolated enum NarrationError: Error, Equatable, Sendable {
    case emptyResponse
    case invalidResponse
    case timeout
}

/// Narración con Apple Foundation Models.
///
/// La sesión se crea solo tras confirmar la disponibilidad del modelo. La
/// generación se cancela al agotar el timeout: nunca bloquea la interfaz.
/// La salida estructurada se valida antes de publicarse: la IA narra, nunca
/// decide ni altera el resultado matemático.
nonisolated struct FoundationModelsNarrationService: CombatNarrationService {
    /// Tiempo máximo de generación antes de cancelar y caer a la plantilla.
    static let timeout: TimeInterval = 20

    /// Temperatura creativa: suficiente variedad entre combates sin perder
    /// coherencia con los datos inmutables del dominio.
    static let temperature: Double = 0.8

    /// Tope de tokens por respuesta: los cuatro beats caben de sobra y no
    /// se desperdicia ventana de contexto.
    static let maximumResponseTokens = 400

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
        let context = NarrationContext(result: result, participants: participants)
        let instructions = NarrationPrompts.instructions(language: language)
        let prompt = NarrationPrompts.combatPrompt(context: context, language: language)
        let timeout = Self.timeout
        let options = GenerationOptions(
            temperature: Self.temperature,
            maximumResponseTokens: Self.maximumResponseTokens
        )

        let narration: GeneratedNarration = try await withThrowingTaskGroup(
            of: GeneratedNarration.self
        ) { group in
            group.addTask {
                let session = LanguageModelSession(instructions: instructions)
                let response = try await session.respond(
                    to: prompt,
                    generating: GeneratedNarration.self,
                    options: options
                )
                return response.content
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

        let text = try NarrationOutputValidator.validatedText(
            from: narration,
            context: context,
            language: language
        )

        return CombatNarrative(text: text, source: .foundationModels)
    }
}

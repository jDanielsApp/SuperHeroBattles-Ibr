import Foundation
import FoundationModels

/// Errores controlados de la narración con IA.
nonisolated enum NarrationError: Error, Equatable, Sendable {
    case emptyResponse
    case invalidResponse
    /// El guardrail de seguridad rechazó la generación. El payload es el
    /// diagnóstico del framework, sin datos personales ni credenciales.
    case guardrail(String)
    case timeout
}

/// Narración con Apple Foundation Models.
///
/// Estrategia ante guardrails: primer intento con el prompt creativo y, si
/// el guardrail lo rechaza, un único reintento con el prompt suavizado y una
/// sesión nueva, dentro del mismo presupuesto total de tiempo. La IA narra,
/// nunca decide ni altera el resultado matemático.
nonisolated struct FoundationModelsNarrationService: CombatNarrationService {
    /// Presupuesto total de generación (ambos intentos) antes de caer a la
    /// plantilla.
    static let timeout: TimeInterval = 20

    /// Temperatura creativa: suficiente variedad entre combates sin perder
    /// coherencia con los datos inmutables del dominio.
    static let temperature: Double = 0.8

    /// Tope de tokens por respuesta: los cuatro beats caben de sobra y no
    /// se desperdicia ventana de contexto.
    static let maximumResponseTokens = 400

    /// Un intento de generación: instrucciones, prompt y tiempo restante.
    /// Seam inyectable para probar la estrategia de reintento sin invocar
    /// el modelo real.
    typealias Attempt = @Sendable (
        _ instructions: String,
        _ prompt: String,
        _ remainingBudget: TimeInterval
    ) async throws -> GeneratedNarration

    private let attempt: Attempt

    init(attempt: @escaping Attempt = Self.foundationModelsAttempt) {
        self.attempt = attempt
    }

    var availability: NarrationAvailability {
        get async {
            // Puerta de entrada según AGENTS.md: siempre sobre el modelo por
            // defecto, aunque las sesiones usen guardrails permisivas.
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
        try Task.checkCancellation()

        let context = NarrationContext(result: result, participants: participants)
        let deadline = Date().addingTimeInterval(Self.timeout)

        do {
            return try await generate(
                instructions: NarrationPrompts.instructions(language: language, safeMode: false),
                prompt: NarrationPrompts.combatPrompt(context: context, language: language),
                context: context,
                language: language,
                deadline: deadline
            )
        } catch {
            let classified = NarrationErrorClassifier.classify(error)
            guard case NarrationError.guardrail = classified else {
                throw classified
            }
        }

        // Reintento único con vocabulario familiar y sesión nueva.
        try Task.checkCancellation()

        do {
            return try await generate(
                instructions: NarrationPrompts.instructions(language: language, safeMode: true),
                prompt: NarrationPrompts.combatPrompt(context: context, language: language),
                context: context,
                language: language,
                deadline: deadline
            )
        } catch {
            throw NarrationErrorClassifier.classify(error)
        }
    }

    // MARK: - Generación

    private func generate(
        instructions: String,
        prompt: String,
        context: NarrationContext,
        language: NarrationLanguage,
        deadline: Date
    ) async throws -> CombatNarrative {
        let remaining = deadline.timeIntervalSinceNow
        guard remaining > 0 else {
            throw NarrationError.timeout
        }

        let narration = try await attempt(instructions, prompt, remaining)
        let text = try NarrationOutputValidator.validatedText(
            from: narration,
            context: context,
            language: language
        )

        return CombatNarrative(text: text, source: .foundationModels)
    }

    /// Intento real con Foundation Models.
    ///
    /// Las sesiones usan `permissiveContentTransformations` para reducir
    /// falsos positivos del guardrail en narración ficticia de superhéroes,
    /// con timeout propio por intento que respeta el presupuesto total.
    private static func foundationModelsAttempt(
        instructions: String,
        prompt: String,
        remainingBudget: TimeInterval
    ) async throws -> GeneratedNarration {
        let model = SystemLanguageModel(
            useCase: .general,
            guardrails: .permissiveContentTransformations
        )

        return try await withThrowingTaskGroup(of: GeneratedNarration.self) { group in
            group.addTask {
                let session = LanguageModelSession(model: model, instructions: instructions)
                let response = try await session.respond(
                    to: prompt,
                    generating: GeneratedNarration.self,
                    options: GenerationOptions(
                        temperature: Self.temperature,
                        maximumResponseTokens: Self.maximumResponseTokens
                    )
                )
                return response.content
            }

            group.addTask {
                try await Task.sleep(for: .seconds(remainingBudget))
                throw NarrationError.timeout
            }

            defer { group.cancelAll() }

            guard let first = try await group.next() else {
                throw NarrationError.timeout
            }
            return first
        }
    }
}

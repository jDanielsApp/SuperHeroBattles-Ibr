import Foundation
import FoundationModels

/// Typed errors for AI narration.
nonisolated enum NarrationError: Error, Equatable, Sendable {
    case emptyResponse
    case invalidResponse
    /// The safety guardrail rejected the generation. The payload is the
    /// framework's diagnostic, containing no personal data or credentials.
    case guardrail(String)
    case timeout
}

/// Narration with Apple Foundation Models.
///
/// Guardrail strategy: first attempt with the creative prompt and, if the
/// guardrail rejects it, a single retry with the softened prompt and a new
/// session, within the same total time budget. The AI narrates; it never
/// decides or alters the mathematical result.
nonisolated struct FoundationModelsNarrationService: CombatNarrationService {
    /// Total generation budget (both attempts) before falling back to
    /// the template.
    static let timeout: TimeInterval = 20

    /// Temperature for the creative attempt: variety across battles
    /// without losing coherence with the domain's immutable data.
    static let creativeTemperature: Double = 0.8

    /// Temperature for the safe retry: less deviation from the prompt and
    /// stronger adherence to the rules after a guardrail rejection.
    static let safeTemperature: Double = 0.5

    /// Maximum tokens per response: the four beats fit comfortably and
    /// no context window is wasted.
    static let maximumResponseTokens = 400

    /// A single generation attempt: instructions, prompt, temperature,
    /// and remaining time. Injectable seam to test the retry strategy
    /// without invoking the real model.
    typealias Attempt = @Sendable (
        _ instructions: String,
        _ prompt: String,
        _ temperature: Double,
        _ remainingBudget: TimeInterval
    ) async throws -> GeneratedNarration

    private let attempt: Attempt

    init(attempt: @escaping Attempt = Self.foundationModelsAttempt) {
        self.attempt = attempt
    }

    var availability: NarrationAvailability {
        get async {
            // The availability gate is always checked on the default
            // model, even though the sessions use permissive guardrails.
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
                temperature: Self.creativeTemperature,
                context: context,
                deadline: deadline
            )
        } catch {
            let classified = NarrationErrorClassifier.classify(error)
            guard case NarrationError.guardrail = classified else {
                throw classified
            }
        }

        // Single retry with family-friendly vocabulary and a new session.
        try Task.checkCancellation()

        do {
            return try await generate(
                instructions: NarrationPrompts.instructions(language: language, safeMode: true),
                prompt: NarrationPrompts.combatPrompt(context: context, language: language),
                temperature: Self.safeTemperature,
                context: context,
                deadline: deadline
            )
        } catch {
            throw NarrationErrorClassifier.classify(error)
        }
    }

    // MARK: - Generation

    private func generate(
        instructions: String,
        prompt: String,
        temperature: Double,
        context: NarrationContext,
        deadline: Date
    ) async throws -> CombatNarrative {
        let remaining = deadline.timeIntervalSinceNow
        guard remaining > 0 else {
            throw NarrationError.timeout
        }

        let narration = try await attempt(instructions, prompt, temperature, remaining)
        let text = try NarrationOutputValidator.validatedText(
            from: narration,
            context: context
        )

        return CombatNarrative(text: text, source: .foundationModels)
    }

    /// Real attempt using Foundation Models.
    ///
    /// Sessions use `permissiveContentTransformations` to reduce guardrail
    /// false positives on fictional superhero narration, with a per-attempt
    /// timeout that respects the total budget.
    private static func foundationModelsAttempt(
        instructions: String,
        prompt: String,
        temperature: Double,
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
                        temperature: temperature,
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

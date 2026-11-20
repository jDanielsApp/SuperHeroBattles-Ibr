import Foundation
import FoundationModels

/// Classifies Foundation Models errors into our own typed errors.
///
/// It distinguishes cancellation (preserved as-is) and safety guardrail
/// violations (iOS 26 and iOS 27, with a text-based fallback so it can be
/// tested without invoking the real model). All other errors pass through
/// unchanged.
nonisolated enum NarrationErrorClassifier {
    /// Returns the classified error, leaving cancellation untouched.
    static func classify(_ error: Error) -> Error {
        if error is CancellationError {
            return error
        }
        if let narrationError = error as? NarrationError {
            return narrationError
        }
        if isGuardrail(error) {
            return NarrationError.guardrail(String(describing: error))
        }
        return error
    }

    /// Is this a safety guardrail violation?
    static func isGuardrail(_ error: Error) -> Bool {
        // iOS 27+: the framework types the guardrail as a LanguageModelError.
        if #available(iOS 27, *) {
            if let modelError = error as? LanguageModelError,
               case .guardrailViolation = modelError {
                return true
            }
        }

        // iOS 26: the guardrail arrives as GenerationError.guardrailViolation.
        if let generationError = error as? LanguageModelSession.GenerationError,
           case .guardrailViolation = generationError {
            return true
        }

        // Text-based fallback: robust against framework variants and lets
        // the classification be tested without the real model.
        let description = String(describing: error).lowercased()
        return description.contains("guardrail")
    }
}

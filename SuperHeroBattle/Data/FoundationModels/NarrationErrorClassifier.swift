import Foundation
import FoundationModels

/// Clasifica los errores de Foundation Models en errores tipados propios.
///
/// Distingue la cancelación (se preserva tal cual) y las violaciones del
/// guardrail de seguridad (iOS 26 e iOS 27, con respaldo textual para poder
/// probarlo sin invocar el modelo real). El resto de errores pasan intactos.
nonisolated enum NarrationErrorClassifier {
    /// Devuelve el error clasificado sin alterar la cancelación.
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

    /// ¿Es una violación del guardrail de seguridad?
    static func isGuardrail(_ error: Error) -> Bool {
        // iOS 27+: el framework tipa el guardrail en LanguageModelError.
        if #available(iOS 27, *) {
            if let modelError = error as? LanguageModelError,
               case .guardrailViolation = modelError {
                return true
            }
        }

        // iOS 26: el guardrail llega como GenerationError.guardrailViolation.
        if let generationError = error as? LanguageModelSession.GenerationError,
           case .guardrailViolation = generationError {
            return true
        }

        // Respaldo textual: robusto ante variantes del framework y permite
        // probar la clasificación sin depender del modelo real.
        let description = String(describing: error).lowercased()
        return description.contains("guardrail")
    }
}

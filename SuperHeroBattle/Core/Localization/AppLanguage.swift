import Foundation

/// Idioma seleccionado por el usuario para la interfaz y las narraciones.
nonisolated enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case english = "en"
    case spanish = "es"

    var id: String { rawValue }

    var locale: Locale? {
        switch self {
        case .system:
            nil
        case .english:
            Locale(identifier: "en")
        case .spanish:
            Locale(identifier: "es")
        }
    }

    /// Código que se envía a Foundation Models. `system` se resuelve con el locale actual.
    var narrationCode: String {
        switch self {
        case .system:
            Locale.current.language.languageCode?.identifier ?? "en"
        case .english:
            "en"
        case .spanish:
            "es"
        }
    }
}

import Foundation

/// Language selected by the user for the interface and narrations.
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

    /// Code sent to Foundation Models. `system` resolves to the current locale.
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

import Foundation
import SwiftUI

/// Single access point for localized text.
nonisolated enum L10n {
    /// Text for use inside SwiftUI, honoring the environment's `locale`.
    static func text(_ key: LocalizableStringKey) -> Text {
        Text(LocalizedStringKey(key.rawValue))
    }

    /// Localized key for SwiftUI APIs that require `LocalizedStringKey`
    /// (for example, a `TextField` placeholder or a `navigationTitle`).
    static func localizedKey(_ key: LocalizableStringKey) -> LocalizedStringKey {
        LocalizedStringKey(key.rawValue)
    }

    /// Plain string for accessibility, errors, or presentation models.
    ///
    /// The explicit locale selects the translation table through the
    /// matching `lproj` bundle: `String(localized:)` does not guarantee
    /// that selection and always answers in the process language.
    static func string(_ key: LocalizableStringKey, locale: Locale = .current) -> String {
        bundle(for: locale)
            .localizedString(forKey: key.rawValue, value: key.rawValue, table: nil)
    }

    /// Bundle for the requested translation; `.main` if the `lproj` is missing.
    private static func bundle(for locale: Locale) -> Bundle {
        guard let languageCode = locale.language.languageCode?.identifier,
              let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let localizedBundle = Bundle(path: path) else {
            return .main
        }
        return localizedBundle
    }
}

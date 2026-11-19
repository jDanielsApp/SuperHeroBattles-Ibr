import Foundation
import SwiftUI

/// Punto único de acceso a los textos localizados.
nonisolated enum L10n {
    /// Texto para usar dentro de SwiftUI, respetando el `locale` del entorno.
    static func text(_ key: LocalizableStringKey) -> Text {
        Text(LocalizedStringKey(key.rawValue))
    }

    /// Clave localizada para APIs de SwiftUI que exigen `LocalizedStringKey`
    /// (por ejemplo, el placeholder de un `TextField` o un `navigationTitle`).
    static func localizedKey(_ key: LocalizableStringKey) -> LocalizedStringKey {
        LocalizedStringKey(key.rawValue)
    }

    /// Texto plano para accesibilidad, errores o modelos de presentación.
    ///
    /// El locale explícito selecciona la tabla de traducción mediante el
    /// bundle del `lproj` correspondiente: `String(localized:)` no garantiza
    /// esa selección y siempre responde en el idioma del proceso.
    static func string(_ key: LocalizableStringKey, locale: Locale = .current) -> String {
        bundle(for: locale)
            .localizedString(forKey: key.rawValue, value: key.rawValue, table: nil)
    }

    /// Bundle de la traducción pedida; `.main` si no existe el `lproj`.
    private static func bundle(for locale: Locale) -> Bundle {
        guard let languageCode = locale.language.languageCode?.identifier,
              let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let localizedBundle = Bundle(path: path) else {
            return .main
        }
        return localizedBundle
    }
}

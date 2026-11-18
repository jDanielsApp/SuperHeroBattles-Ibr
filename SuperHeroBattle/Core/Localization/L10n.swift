import Foundation
import SwiftUI

/// Punto único de acceso a los textos localizados.
nonisolated enum L10n {
    /// Texto para usar dentro de SwiftUI, respetando el `locale` del entorno.
    static func text(_ key: LocalizableStringKey) -> Text {
        Text(LocalizedStringKey(key.rawValue))
    }

    /// Texto plano para accesibilidad, errores o modelos de presentación.
    static func string(_ key: LocalizableStringKey, locale: Locale = .current) -> String {
        String(
            localized: String.LocalizationValue(key.rawValue),
            bundle: .main,
            locale: locale
        )
    }
}

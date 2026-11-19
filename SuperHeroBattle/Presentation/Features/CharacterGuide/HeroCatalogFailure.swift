import Foundation

/// Errores presentables del catálogo local. La vista solo muestra claves localizadas.
nonisolated enum HeroCatalogFailure: Equatable, Sendable {
    case unavailable
    case empty
    case remote(HeroSearchFailure)

    var titleKey: LocalizableStringKey {
        .guideCatalogErrorTitle
    }

    var messageKey: LocalizableStringKey {
        switch self {
        case .unavailable:
            .guideCatalogErrorUnavailable
        case .empty:
            .guideCatalogErrorEmpty
        case .remote(let failure):
            failure.messageKey
        }
    }
}

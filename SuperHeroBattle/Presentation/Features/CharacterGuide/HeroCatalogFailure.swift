import Foundation

/// Presentable errors for the local catalog. The view only shows localized keys.
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

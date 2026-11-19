import Foundation

/// Errores presentables de la búsqueda. La vista solo muestra claves localizadas.
nonisolated enum HeroSearchFailure: Equatable, Sendable {
    case notConfigured
    case offline
    case unauthorized
    case rateLimited
    case server
    case unexpected

    init(error: HeroRepositoryError) {
        switch error {
        case .notConfigured:
            self = .notConfigured
        case .transport:
            self = .offline
        case .unauthorized:
            self = .unauthorized
        case .rateLimited:
            self = .rateLimited
        case .server:
            self = .server
        case .notFound, .invalidResponse, .decoding, .api:
            self = .unexpected
        }
    }

    var titleKey: LocalizableStringKey {
        .searchErrorTitle
    }

    var messageKey: LocalizableStringKey {
        switch self {
        case .notConfigured:
            .searchErrorNotConfigured
        case .offline:
            .searchErrorOffline
        case .unauthorized:
            .searchErrorUnauthorized
        case .rateLimited:
            .searchErrorRateLimited
        case .server:
            .searchErrorServer
        case .unexpected:
            .searchErrorUnexpected
        }
    }
}

import Foundation

/// Domain errors for remote SuperHeroAPI access.
/// They never include the URL or the token: the token travels in the request path.
nonisolated enum HeroRepositoryError: Error, Equatable, Sendable {
    case notConfigured
    case notFound
    case transport
    case invalidResponse
    case decoding
    case server(status: Int)
    case unauthorized
    case rateLimited
    case api(message: String)
}

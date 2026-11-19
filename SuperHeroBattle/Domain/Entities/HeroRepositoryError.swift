import Foundation

/// Errores de dominio del acceso remoto a SuperHeroAPI.
/// No incluyen la URL ni el token: el token viaja en la ruta de la petición.
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

import Foundation

/// Respuesta de error de SuperHeroAPI. Puede llegar con HTTP 200.
nonisolated struct APIErrorDTO: Decodable, Sendable {
    let response: String?
    let error: String?
}

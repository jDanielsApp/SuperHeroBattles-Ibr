import Foundation

/// Error response from SuperHeroAPI. It can arrive with HTTP 200.
nonisolated struct APIErrorDTO: Decodable, Sendable {
    let response: String?
    let error: String?
}

import Foundation

/// Acceso remoto a SuperHeroAPI.
nonisolated protocol HeroRepository: Sendable {
    func search(query: String) async throws -> [Hero]
    func hero(id: String) async throws -> Hero
}

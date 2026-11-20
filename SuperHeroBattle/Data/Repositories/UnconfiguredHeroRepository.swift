import Foundation

/// Fallback repository used when the API configuration is missing.
/// It lets the app launch and surface a readable error from search.
nonisolated struct UnconfiguredHeroRepository: HeroRepository {
    func search(query: String) async throws -> [Hero] {
        throw HeroRepositoryError.notConfigured
    }

    func hero(id: String) async throws -> Hero {
        throw HeroRepositoryError.notConfigured
    }
}

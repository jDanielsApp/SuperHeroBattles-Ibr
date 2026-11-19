import Foundation

/// Decorador que añade caché TTL a las búsquedas y deja el detalle sin cachear.
nonisolated struct CachedHeroRepository: HeroRepository {
    private let remote: any HeroRepository
    private let cache: HeroSearchCache

    init(remote: any HeroRepository, cache: HeroSearchCache) {
        self.remote = remote
        self.cache = cache
    }

    func search(query: String) async throws -> [Hero] {
        let query = SearchQueryNormalizer.normalizedQuery(query)
        guard !query.isEmpty else { return [] }

        let key = SearchQueryNormalizer.cacheKey(query)

        if let cached = await cache.heroes(for: key) {
            try Task.checkCancellation()
            return cached
        }

        try Task.checkCancellation()
        let heroes = try await remote.search(query: query)
        try Task.checkCancellation()
        await cache.store(heroes, for: key)
        return heroes
    }

    func hero(id: String) async throws -> Hero {
        try await remote.hero(id: id)
    }
}

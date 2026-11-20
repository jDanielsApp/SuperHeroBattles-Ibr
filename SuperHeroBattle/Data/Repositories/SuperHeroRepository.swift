import Foundation

/// Remote implementation of `HeroRepository`.
nonisolated struct SuperHeroRepository: HeroRepository {
    private let client: SuperHeroAPIClient
    private let mapper: HeroMapper

    init(client: SuperHeroAPIClient, mapper: HeroMapper = HeroMapper()) {
        self.client = client
        self.mapper = mapper
    }

    func search(query: String) async throws -> [Hero] {
        do {
            let results = try await client.fetchHeroes(query: query)
            return results.compactMap { mapper.map($0) }
        } catch HeroRepositoryError.notFound {
            return []
        } catch let HeroRepositoryError.api(message) where Self.isNotFound(message) {
            return []
        }
    }

    func hero(id: String) async throws -> Hero {
        do {
            let dto = try await client.fetchHero(id: id)
            guard let hero = mapper.map(dto) else {
                throw HeroRepositoryError.decoding
            }
            return hero
        } catch let HeroRepositoryError.api(message) where Self.isNotFound(message) {
            throw HeroRepositoryError.notFound
        }
    }

    private static func isNotFound(_ message: String) -> Bool {
        let lowercased = message.lowercased()
        return lowercased.contains("not found") || lowercased.contains("no results")
    }
}

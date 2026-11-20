import Foundation

/// In-memory catalog used as a fallback when Realm is unavailable
/// and as a supporting implementation in tests.
actor InMemoryHeroCatalogRepository: HeroCatalogRepository {
    private var storage: [String: Hero] = [:]

    init(heroes: [Hero] = []) {
        for hero in heroes {
            storage[hero.id] = hero
        }
    }

    func allHeroes() async throws -> [Hero] {
        storage.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    func hero(id: String) async throws -> Hero? {
        storage[id]
    }

    func heroes(ids: [String]) async throws -> [Hero] {
        ids.compactMap { storage[$0] }
    }

    func upsert(_ heroes: [Hero]) async throws {
        for hero in heroes {
            storage[hero.id] = hero
        }
    }
}

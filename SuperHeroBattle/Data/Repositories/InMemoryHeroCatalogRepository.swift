import Foundation

/// Catálogo en memoria usado como respaldo cuando Realm no está disponible
/// y como implementación de apoyo en tests.
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

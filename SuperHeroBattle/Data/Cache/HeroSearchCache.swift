import Foundation

/// Caché en memoria con TTL para búsquedas de héroes.
/// La clave es la query normalizada y no se cachean errores.
actor HeroSearchCache {
    private struct Entry {
        let heroes: [Hero]
        let storedAt: Date
    }

    private let configuration: HeroSearchCacheConfiguration
    private let timeProvider: any TimeProvider
    private var entries: [String: Entry] = [:]

    init(
        configuration: HeroSearchCacheConfiguration = .default,
        timeProvider: any TimeProvider = SystemTimeProvider()
    ) {
        self.configuration = configuration
        self.timeProvider = timeProvider
    }

    func heroes(for key: String) -> [Hero]? {
        guard let entry = entries[key] else { return nil }

        let age = timeProvider.now.timeIntervalSince(entry.storedAt)
        guard age >= 0, age < configuration.timeToLive else {
            entries[key] = nil
            return nil
        }

        return entry.heroes
    }

    func store(_ heroes: [Hero], for key: String) {
        entries[key] = Entry(heroes: heroes, storedAt: timeProvider.now)
    }

    func removeAll() {
        entries.removeAll()
    }
}

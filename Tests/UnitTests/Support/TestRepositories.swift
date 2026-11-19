import Foundation
@testable import SuperHeroBattle

/// Catálogo observable desde los tests: guarda los upserts recibidos.
actor SpyCatalogRepository: HeroCatalogRepository {
    private var storage: [String: Hero]
    private var upsertedBatches: [[Hero]] = []

    init(heroes: [Hero] = []) {
        storage = Dictionary(
            heroes.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    func allHeroes() async throws -> [Hero] {
        storage.values.sorted { $0.id < $1.id }
    }

    func hero(id: String) async throws -> Hero? {
        storage[id]
    }

    func heroes(ids: [String]) async throws -> [Hero] {
        ids.compactMap { storage[$0] }
    }

    func upsert(_ heroes: [Hero]) async throws {
        upsertedBatches.append(heroes)
        for hero in heroes {
            storage[hero.id] = hero
        }
    }

    func upsertedIDs() -> [String] {
        upsertedBatches.flatMap { $0.map(\.id) }
    }

    func storedIDs() -> Set<String> {
        Set(storage.keys)
    }
}

/// Repositorio remoto con un resultado intercambiable entre llamadas.
actor SwitchableHeroRepository: HeroRepository {
    private var outcome: StubHeroOutcome

    init(_ outcome: StubHeroOutcome) {
        self.outcome = outcome
    }

    func setOutcome(_ outcome: StubHeroOutcome) {
        self.outcome = outcome
    }

    func search(query: String) async throws -> [Hero] {
        try result()
    }

    func hero(id: String) async throws -> Hero {
        switch outcome {
        case .success(let heroes):
            guard let hero = heroes.first(where: { $0.id == id }) else {
                throw HeroRepositoryError.notFound
            }
            return hero
        case .failure(let error):
            throw error
        case .cancellation:
            throw CancellationError()
        }
    }

    private func result() throws -> [Hero] {
        switch outcome {
        case .success(let heroes):
            return heroes
        case .failure(let error):
            throw error
        case .cancellation:
            throw CancellationError()
        }
    }
}

/// Repositorio remoto con éxitos y fallos por ID.
nonisolated struct PerIDHeroRepository: HeroRepository {
    let heroes: [String: Hero]
    let failures: [String: HeroRepositoryError]

    init(heroes: [Hero] = [], failures: [String: HeroRepositoryError] = [:]) {
        self.heroes = Dictionary(
            heroes.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        self.failures = failures
    }

    func search(query: String) async throws -> [Hero] {
        Array(heroes.values)
    }

    func hero(id: String) async throws -> Hero {
        if let failure = failures[id] {
            throw failure
        }
        guard let hero = heroes[id] else {
            throw HeroRepositoryError.notFound
        }
        return hero
    }
}

/// Repositorio remoto que suspende cada petición hasta que el test la libera.
/// Permite medir la concurrencia real del caso de uso.
actor GatedHeroRepository: HeroRepository {
    private let heroes: [String: Hero]
    private var failures: [String: HeroRepositoryError]
    private var continuations: [String: CheckedContinuation<Hero, Error>] = [:]
    private var active = 0
    private var maxActive = 0
    private var started: [String] = []

    init(heroes: [Hero], failures: [String: HeroRepositoryError] = [:]) {
        self.heroes = Dictionary(
            heroes.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        self.failures = failures
    }

    func search(query: String) async throws -> [Hero] {
        Array(heroes.values)
    }

    func hero(id: String) async throws -> Hero {
        active += 1
        maxActive = max(maxActive, active)
        started.append(id)

        if let failure = failures[id] {
            active -= 1
            throw failure
        }

        guard heroes[id] != nil else {
            active -= 1
            throw HeroRepositoryError.notFound
        }

        return try await withCheckedThrowingContinuation { continuation in
            continuations[id] = continuation
        }
    }

    func complete(id: String) {
        guard let continuation = continuations.removeValue(forKey: id) else { return }
        active -= 1
        continuation.resume(returning: heroes[id] ?? Hero(id: id, name: id))
    }

    func completeAllPending() {
        let ids = Array(continuations.keys)
        for id in ids {
            complete(id: id)
        }
    }

    func startedIDs() -> [String] {
        started
    }

    func maxConcurrent() -> Int {
        maxActive
    }

    func pendingCount() -> Int {
        continuations.count
    }
}

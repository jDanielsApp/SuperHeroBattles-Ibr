import Foundation
@testable import SuperHeroBattle

/// Catalog observable from tests: stores the upserts it receives.
nonisolated final class SpyCatalogRepository: HeroCatalogRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: Hero]
    private var upsertedBatches: [[Hero]] = []

    init(heroes: [Hero] = []) {
        self.storage = Dictionary(
            heroes.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    func allHeroes() async throws -> [Hero] {
        lock.withLock { storage.values.sorted { $0.id < $1.id } }
    }

    func hero(id: String) async throws -> Hero? {
        lock.withLock { storage[id] }
    }

    func heroes(ids: [String]) async throws -> [Hero] {
        lock.withLock { ids.compactMap { storage[$0] } }
    }

    func upsert(_ heroes: [Hero]) async throws {
        lock.withLock {
            upsertedBatches.append(heroes)
            for hero in heroes {
                storage[hero.id] = hero
            }
        }
    }

    func upsertedIDs() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return upsertedBatches.flatMap { $0.map(\.id) }
    }

    func storedIDs() -> Set<String> {
        lock.lock()
        defer { lock.unlock() }
        return Set(storage.keys)
    }
}

/// Remote repository with an outcome that can be swapped between calls.
nonisolated final class SwitchableHeroRepository: HeroRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var outcome: StubHeroOutcome

    init(_ outcome: StubHeroOutcome) {
        self.outcome = outcome
    }

    func setOutcome(_ outcome: StubHeroOutcome) {
        lock.lock()
        defer { lock.unlock() }
        self.outcome = outcome
    }

    func search(query: String) async throws -> [Hero] {
        try result()
    }

    func hero(id: String) async throws -> Hero {
        try lock.withLock {
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
    }

    private func result() throws -> [Hero] {
        lock.lock()
        defer { lock.unlock() }

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

/// Remote repository with per-ID successes and failures.
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

/// Remote repository that suspends each request until the test releases it.
/// Allows measuring the use case's real concurrency.
nonisolated final class GatedHeroRepository: HeroRepository, @unchecked Sendable {
    private let lock = NSLock()
    private let heroes: [String: Hero]
    private let failures: [String: HeroRepositoryError]
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
        lock.withLock {
            active += 1
            maxActive = max(maxActive, active)
            started.append(id)
        }

        if let failure = failures[id] {
            lock.withLock { active -= 1 }
            throw failure
        }

        guard heroes[id] != nil else {
            lock.withLock { active -= 1 }
            throw HeroRepositoryError.notFound
        }

        return try await withCheckedThrowingContinuation { continuation in
            lock.withLock { continuations[id] = continuation }
        }
    }

    func complete(id: String) {
        lock.lock()
        let continuation = continuations.removeValue(forKey: id)
        if continuation != nil {
            active -= 1
        }
        lock.unlock()

        continuation?.resume(returning: heroes[id] ?? Hero(id: id, name: id))
    }

    func completeAllPending() {
        lock.lock()
        let ids = Array(continuations.keys)
        lock.unlock()

        for id in ids {
            complete(id: id)
        }
    }

    func startedIDs() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return started
    }

    func maxConcurrent() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return maxActive
    }

    func pendingCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return continuations.count
    }
}

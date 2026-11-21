import Foundation
@testable import SuperHeroBattle

nonisolated enum StubHeroOutcome: Sendable {
    case success([Hero])
    case failure(HeroRepositoryError)
    case cancellation
}

/// Fake repository with a single immediate outcome.
nonisolated struct StubHeroRepository: HeroRepository {
    let outcome: StubHeroOutcome

    func search(query: String) async throws -> [Hero] {
        switch outcome {
        case .success(let heroes):
            return heroes
        case .failure(let error):
            throw error
        case .cancellation:
            throw CancellationError()
        }
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
}

/// Fake repository with a sequence of outcomes that records received queries.
nonisolated final class ScriptedHeroRepository: HeroRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var outcomes: [StubHeroOutcome]
    private var queries: [String] = []

    init(_ outcomes: [StubHeroOutcome]) {
        self.outcomes = outcomes
    }

    func search(query: String) async throws -> [Hero] {
        try lock.withLock {
            queries.append(query)

            guard !outcomes.isEmpty else {
                throw HeroRepositoryError.transport
            }

            switch outcomes.removeFirst() {
            case .success(let heroes):
                return heroes
            case .failure(let error):
                throw error
            case .cancellation:
                throw CancellationError()
            }
        }
    }

    func hero(id: String) async throws -> Hero {
        throw HeroRepositoryError.notFound
    }

    func recordedQueries() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return queries
    }
}

/// Repository that counts calls to verify the cache.
nonisolated final class CountingHeroRepository: HeroRepository, @unchecked Sendable {
    private let lock = NSLock()
    private let heroes: [Hero]
    private var searchCount = 0

    init(heroes: [Hero]) {
        self.heroes = heroes
    }

    func search(query: String) async throws -> [Hero] {
        lock.withLock { searchCount += 1 }
        return heroes
    }

    func hero(id: String) async throws -> Hero {
        guard let hero = heroes.first(where: { $0.id == id }) else {
            throw HeroRepositoryError.notFound
        }
        return hero
    }

    func count() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return searchCount
    }
}

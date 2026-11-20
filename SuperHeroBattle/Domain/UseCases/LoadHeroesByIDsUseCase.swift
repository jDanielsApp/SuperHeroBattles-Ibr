import Foundation

/// Loads the profiles for a page of IDs using the local cache first.
///
/// - IDs already persisted generate no network requests.
/// - Missing IDs are downloaded with bounded concurrency.
/// - A `notFound` is skipped without breaking the page.
/// - Any other network error is propagated so the UI can offer a retry.
nonisolated struct LoadHeroesByIDsUseCase: Sendable {
    static let defaultMaxConcurrentRequests = 6

    private let catalog: any HeroCatalogRepository
    private let remote: any HeroRepository
    private let maxConcurrentRequests: Int

    init(
        catalog: any HeroCatalogRepository,
        remote: any HeroRepository,
        maxConcurrentRequests: Int = LoadHeroesByIDsUseCase.defaultMaxConcurrentRequests
    ) {
        self.catalog = catalog
        self.remote = remote
        self.maxConcurrentRequests = max(1, maxConcurrentRequests)
    }

    func execute(ids: [String]) async throws -> [Hero] {
        guard !ids.isEmpty else { return [] }
        try Task.checkCancellation()

        let cached = try await catalog.heroes(ids: ids)
        try Task.checkCancellation()

        let cachedByID = Dictionary(
            cached.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let missingIDs = ids.filter { cachedByID[$0] == nil }

        guard !missingIDs.isEmpty else {
            return ids.compactMap { cachedByID[$0] }
        }

        let outcome = try await fetch(ids: missingIDs)
        try Task.checkCancellation()

        if !outcome.heroes.isEmpty {
            try await catalog.upsert(outcome.heroes)
        }

        if let failure = outcome.failure {
            throw failure
        }

        var resolved = cachedByID
        for hero in outcome.heroes {
            resolved[hero.id] = hero
        }
        return ids.compactMap { resolved[$0] }
    }

    private func fetch(ids: [String]) async throws -> FetchOutcome {
        var heroes: [Hero] = []
        var failure: Error?

        try await withThrowingTaskGroup(of: FetchResult.self) { group in
            var iterator = ids.makeIterator()
            let initialCount = min(maxConcurrentRequests, ids.count)

            for _ in 0..<initialCount {
                guard let id = iterator.next() else { break }
                addTask(for: id, to: &group)
            }

            while let result = try await group.next() {
                switch result.outcome {
                case .success(let hero):
                    if let hero {
                        heroes.append(hero)
                    }
                case .failure(let error):
                    if error is CancellationError {
                        group.cancelAll()
                        throw CancellationError()
                    }
                    if failure == nil {
                        failure = error
                    }
                }

                if let id = iterator.next() {
                    addTask(for: id, to: &group)
                }
            }
        }

        return FetchOutcome(heroes: heroes, failure: failure)
    }

    private func addTask(
        for id: String,
        to group: inout ThrowingTaskGroup<FetchResult, Error>
    ) {
        let remote = remote
        group.addTask {
            do {
                let hero = try await remote.hero(id: id)
                return FetchResult(id: id, outcome: .success(hero))
            } catch HeroRepositoryError.notFound {
                return FetchResult(id: id, outcome: .success(nil))
            } catch {
                return FetchResult(id: id, outcome: .failure(error))
            }
        }
    }
}

private extension LoadHeroesByIDsUseCase {
    struct FetchResult: Sendable {
        let id: String
        let outcome: Result<Hero?, Error>
    }

    struct FetchOutcome: Sendable {
        let heroes: [Hero]
        let failure: Error?
    }
}

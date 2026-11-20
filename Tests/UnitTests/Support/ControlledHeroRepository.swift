import Foundation
import XCTest
@testable import SuperHeroBattle

/// Controllable repository: searches stay suspended until the test completes them.
nonisolated final class ControlledHeroRepository: HeroRepository, @unchecked Sendable {
    typealias SearchResult = Result<[Hero], Error>

    private let lock = NSLock()
    private var continuations: [String: CheckedContinuation<[Hero], Error>] = [:]
    private var startHandler: ((String) -> Void)?

    func onSearchStart(_ handler: ((String) -> Void)?) {
        lock.lock()
        defer { lock.unlock() }
        startHandler = handler
    }

    func search(query: String) async throws -> [Hero] {
        let handler = currentStartHandler()

        return try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            continuations[query] = continuation
            lock.unlock()

            handler?(query)
        }
    }

    func hero(id: String) async throws -> Hero {
        throw HeroRepositoryError.notFound
    }

    func complete(query: String, heroes: [Hero]) {
        resume(query: query, with: .success(heroes))
    }

    func fail(query: String, error: HeroRepositoryError) {
        resume(query: query, with: .failure(error))
    }

    func cancel(query: String) {
        resume(query: query, with: .failure(CancellationError()))
    }

    private func currentStartHandler() -> ((String) -> Void)? {
        lock.lock()
        defer { lock.unlock() }
        return startHandler
    }

    private func resume(query: String, with result: SearchResult) {
        lock.lock()
        let continuation = continuations.removeValue(forKey: query)
        lock.unlock()
        continuation?.resume(with: result)
    }
}

import XCTest
@testable import SuperHeroBattle

final class CachedHeroRepositoryTests: XCTestCase {
    func testSecondEquivalentQueryUsesCache() async throws {
        try await withRepository { repository, remote, _ in
            _ = try await repository.search(query: "  Batman  ")
            _ = try await repository.search(query: "batman")
            _ = try await repository.search(query: "BÁTMAN")

            let count = await remote.count()
            XCTAssertEqual(count, 1)
        }
    }

    func testDifferentQueriesAreIsolated() async throws {
        try await withRepository { repository, remote, _ in
            _ = try await repository.search(query: "batman")
            _ = try await repository.search(query: "superman")

            let count = await remote.count()
            XCTAssertEqual(count, 2)
        }
    }

    func testExpiredEntryTriggersNewRequestAndRefreshesCache() async throws {
        try await withRepository { repository, remote, clock in
            _ = try await repository.search(query: "batman")
            clock.advance(by: 180)
            _ = try await repository.search(query: "batman")

            let afterExpiry = await remote.count()
            XCTAssertEqual(afterExpiry, 2)

            _ = try await repository.search(query: "batman")
            let afterRefresh = await remote.count()
            XCTAssertEqual(afterRefresh, 2)
        }
    }

    func testFailedSearchIsNotCached() async throws {
        let remote = ScriptedHeroRepository([
            .failure(.transport),
            .success([Hero(id: "1", name: "Batman")]),
        ])
        let repository = CachedHeroRepository(
            remote: remote,
            cache: HeroSearchCache(timeProvider: FakeTimeProvider())
        )

        do {
            _ = try await repository.search(query: "batman")
            XCTFail("Expected transport error")
        } catch let error as HeroRepositoryError {
            XCTAssertEqual(error, .transport)
        }

        let heroes = try await repository.search(query: "batman")
        let queries = await remote.recordedQueries()

        XCTAssertEqual(heroes.map(\.id), ["1"])
        XCTAssertEqual(queries, ["batman", "batman"])
    }

    func testEmptyQueryDoesNotReachRemote() async throws {
        let remote = CountingHeroRepository(heroes: [Hero(id: "1", name: "Batman")])
        let repository = CachedHeroRepository(
            remote: remote,
            cache: HeroSearchCache(timeProvider: FakeTimeProvider())
        )

        let heroes = try await repository.search(query: "   ")
        let count = await remote.count()

        XCTAssertTrue(heroes.isEmpty)
        XCTAssertEqual(count, 0)
    }

    func testDetailBypassesSearchCache() async throws {
        let remote = CountingHeroRepository(heroes: [Hero(id: "1", name: "Batman")])
        let repository = CachedHeroRepository(
            remote: remote,
            cache: HeroSearchCache(timeProvider: FakeTimeProvider())
        )

        let hero = try await repository.hero(id: "1")

        XCTAssertEqual(hero.id, "1")
    }

    private func withRepository(
        _ body: (CachedHeroRepository, CountingHeroRepository, FakeTimeProvider) async throws -> Void
    ) async throws {
        let clock = FakeTimeProvider()
        let remote = CountingHeroRepository(heroes: [Hero(id: "1", name: "Batman")])
        let repository = CachedHeroRepository(
            remote: remote,
            cache: HeroSearchCache(timeProvider: clock)
        )
        try await body(repository, remote, clock)
    }
}

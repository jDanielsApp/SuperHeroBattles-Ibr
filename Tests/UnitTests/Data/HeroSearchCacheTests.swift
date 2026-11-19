import XCTest
@testable import SuperHeroBattle

final class HeroSearchCacheTests: XCTestCase {
    func testTimeToLiveIsClampedToAllowedRange() {
        XCTAssertEqual(HeroSearchCacheConfiguration(timeToLive: 10).timeToLive, 120)
        XCTAssertEqual(HeroSearchCacheConfiguration(timeToLive: 180).timeToLive, 180)
        XCTAssertEqual(HeroSearchCacheConfiguration(timeToLive: 9_999).timeToLive, 300)
    }

    func testStoresAndReturnsHeroesWithinTimeToLive() async {
        let clock = FakeTimeProvider()
        let cache = HeroSearchCache(
            configuration: HeroSearchCacheConfiguration(timeToLive: 180),
            timeProvider: clock
        )
        let heroes = [makeHero(id: "1")]

        await cache.store(heroes, for: "batman")
        clock.advance(by: 179)
        let cached = await cache.heroes(for: "batman")

        XCTAssertEqual(cached, heroes)
    }

    func testEntryExpiresAtTimeToLive() async {
        let clock = FakeTimeProvider()
        let cache = HeroSearchCache(
            configuration: HeroSearchCacheConfiguration(timeToLive: 180),
            timeProvider: clock
        )

        await cache.store([makeHero(id: "1")], for: "batman")
        clock.advance(by: 180)
        let cached = await cache.heroes(for: "batman")

        XCTAssertNil(cached)
    }

    func testKeysAreIsolated() async {
        let cache = HeroSearchCache(timeProvider: FakeTimeProvider())
        let batman = [makeHero(id: "1")]
        let superman = [makeHero(id: "2")]

        await cache.store(batman, for: "batman")
        await cache.store(superman, for: "superman")

        let cachedBatman = await cache.heroes(for: "batman")
        let cachedSuperman = await cache.heroes(for: "superman")
        let cachedUnknown = await cache.heroes(for: "wonder woman")

        XCTAssertEqual(cachedBatman, batman)
        XCTAssertEqual(cachedSuperman, superman)
        XCTAssertNil(cachedUnknown)
    }

    func testRemoveAllClearsEntries() async {
        let cache = HeroSearchCache(timeProvider: FakeTimeProvider())
        await cache.store([makeHero(id: "1")], for: "batman")

        await cache.removeAll()

        let cached = await cache.heroes(for: "batman")
        XCTAssertNil(cached)
    }

    func testFutureTimestampIsTreatedAsExpired() async {
        let clock = FakeTimeProvider(now: Date(timeIntervalSince1970: 1_000))
        let cache = HeroSearchCache(timeProvider: clock)
        await cache.store([makeHero(id: "1")], for: "batman")

        clock.advance(by: -10)
        let cached = await cache.heroes(for: "batman")

        XCTAssertNil(cached)
    }

    private func makeHero(id: String) -> Hero {
        Hero(id: id, name: "Hero \(id)")
    }
}

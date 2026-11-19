import RealmSwift
import XCTest
@testable import SuperHeroBattle

@MainActor
final class RealmHeroCatalogRepositoryTests: XCTestCase {
    func testUpsertAndReadRoundTripsTheFullHero() async throws {
        let repository = try makeRepository()

        try await repository.upsert([makeHero()])

        let stored = try await repository.hero(id: "70")
        XCTAssertEqual(stored, makeHero())
    }

    func testBatchReadPreservesRequestedOrder() async throws {
        let repository = try makeRepository()
        let heroes = [
            makeHero(id: "2", name: "Beta"),
            makeHero(id: "1", name: "Alpha"),
            makeHero(id: "3", name: "Gamma"),
        ]
        try await repository.upsert(heroes)

        let result = try await repository.heroes(ids: ["3", "1", "2"])

        XCTAssertEqual(result.map(\.id), ["3", "1", "2"])
    }

    func testBatchReadWithEmptyIDsReturnsEmpty() async throws {
        let repository = try makeRepository()

        let result = try await repository.heroes(ids: [])

        XCTAssertTrue(result.isEmpty)
    }

    func testAllHeroesSortsByName() async throws {
        let repository = try makeRepository()
        try await repository.upsert([
            makeHero(id: "2", name: "Zatanna"),
            makeHero(id: "1", name: "Aquaman"),
        ])

        let result = try await repository.allHeroes()

        XCTAssertEqual(result.map(\.name), ["Aquaman", "Zatanna"])
    }

    func testUpsertUpdatesExistingHeroWithoutDuplicating() async throws {
        let repository = try makeRepository()
        try await repository.upsert([makeHero(name: "Old Name")])
        try await repository.upsert([makeHero(name: "New Name")])

        let all = try await repository.allHeroes()

        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.name, "New Name")
    }

    private func makeRepository() throws -> RealmHeroCatalogRepository {
        try RealmHeroCatalogRepository(
            configuration: RealmStore.configuration(
                inMemory: true,
                inMemoryIdentifier: "catalog-\(UUID().uuidString)"
            )
        )
    }

    private func makeHero(id: String = "70", name: String = "Batman") -> Hero {
        Hero(
            id: id,
            name: name,
            biography: HeroBiography(
                fullName: "Bruce Wayne",
                alterEgos: "No alter egos found.",
                aliases: ["Insider", "Matches Malone"],
                placeOfBirth: "Gotham City",
                firstAppearance: "Detective Comics #27",
                publisher: "DC Comics",
                alignment: .good
            ),
            appearance: HeroAppearance(
                gender: "Male",
                race: "Human",
                height: ["6'2", "188 cm"],
                weight: ["210 lb", "95 kg"],
                eyeColor: "blue",
                hairColor: "black"
            ),
            work: HeroWork(
                occupation: "Businessman",
                base: "Gotham City"
            ),
            connections: HeroConnections(
                groupAffiliation: "Justice League",
                relatives: "Damian Wayne (son)"
            ),
            powerStats: PowerStats(
                intelligence: 100,
                strength: 26,
                speed: 27,
                durability: 50,
                power: 47,
                combat: 100
            ),
            imageURL: URL(string: "https://example.com/batman.jpg")
        )
    }
}

import XCTest
@testable import SuperHeroBattle

final class GenerateRandomHeroUseCaseTests: XCTestCase {
    func testRandomSelectionExcludesRequestedHeroes() async throws {
        let catalog = FakeCatalogRepository(heroes: [
            Hero(id: "1", name: "One"),
            Hero(id: "2", name: "Two"),
            Hero(id: "3", name: "Three"),
        ])
        let useCase = GenerateRandomHeroUseCase(
            catalog: catalog,
            picker: FirstAvailablePicker()
        )

        let hero = try await useCase.execute(excluding: ["1", "3"])

        XCTAssertEqual(hero?.id, "2")
    }

    func testRandomSelectionReturnsNilWhenNoHeroIsAvailable() async throws {
        let catalog = FakeCatalogRepository(heroes: [Hero(id: "1", name: "One")])
        let useCase = GenerateRandomHeroUseCase(
            catalog: catalog,
            picker: FirstAvailablePicker()
        )

        let hero = try await useCase.execute(excluding: ["1"])

        XCTAssertNil(hero)
    }
}

private struct FakeCatalogRepository: HeroCatalogRepository {
    let heroes: [Hero]

    func allHeroes() async throws -> [Hero] { heroes }
    func hero(id: String) async throws -> Hero? { heroes.first { $0.id == id } }
    func heroes(ids: [String]) async throws -> [Hero] {
        ids.compactMap { id in heroes.first { $0.id == id } }
    }
    func upsert(_ heroes: [Hero]) async throws {}
}

private struct FirstAvailablePicker: RandomHeroPicker {
    func pick(from heroes: [Hero], excluding heroIDs: Set<String>) -> Hero? {
        heroes.first { !heroIDs.contains($0.id) }
    }
}

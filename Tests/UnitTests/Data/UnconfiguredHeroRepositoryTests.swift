import XCTest
@testable import SuperHeroBattle

/// Covers the real production path when the SuperHeroAPI token is missing:
/// the app keeps working and every remote operation fails as not configured.
final class UnconfiguredHeroRepositoryTests: XCTestCase {
    func testSearchThrowsNotConfigured() async {
        do {
            _ = try await UnconfiguredHeroRepository().search(query: "batman")
            XCTFail("Se esperaba notConfigured")
        } catch {
            XCTAssertEqual(error as? HeroRepositoryError, .notConfigured)
        }
    }

    func testHeroByIDThrowsNotConfigured() async {
        do {
            _ = try await UnconfiguredHeroRepository().hero(id: "70")
            XCTFail("Se esperaba notConfigured")
        } catch {
            XCTAssertEqual(error as? HeroRepositoryError, .notConfigured)
        }
    }
}

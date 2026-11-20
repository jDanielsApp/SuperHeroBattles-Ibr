import XCTest
@testable import SuperHeroBattle

/// Cubre la ruta real de producción cuando falta el token de SuperHeroAPI:
/// la app sigue funcionando y toda operación remota falla como no configurada.
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

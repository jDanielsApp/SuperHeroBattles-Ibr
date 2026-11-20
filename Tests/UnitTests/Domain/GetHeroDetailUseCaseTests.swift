import XCTest
@testable import SuperHeroBattle

/// Covers the use case kept for future detail improvements.
final class GetHeroDetailUseCaseTests: XCTestCase {
    func testReturnsHeroById() async throws {
        let hero = Hero(id: "70", name: "Batman")
        let useCase = GetHeroDetailUseCase(
            repository: StubHeroRepository(outcome: .success([hero]))
        )

        let result = try await useCase.execute(id: "70")

        XCTAssertEqual(result, hero)
    }

    func testPropagatesNotFoundForUnknownID() async {
        let hero = Hero(id: "70", name: "Batman")
        let useCase = GetHeroDetailUseCase(
            repository: StubHeroRepository(outcome: .success([hero]))
        )

        do {
            _ = try await useCase.execute(id: "999")
            XCTFail("Se esperaba notFound")
        } catch {
            XCTAssertEqual(error as? HeroRepositoryError, .notFound)
        }
    }

    func testPropagatesTransportFailures() async {
        let useCase = GetHeroDetailUseCase(
            repository: StubHeroRepository(outcome: .failure(.transport))
        )

        do {
            _ = try await useCase.execute(id: "70")
            XCTFail("Se esperaba un error de transporte")
        } catch {
            XCTAssertEqual(error as? HeroRepositoryError, .transport)
        }
    }

    func testPropagatesCancellation() async {
        let useCase = GetHeroDetailUseCase(
            repository: StubHeroRepository(outcome: .cancellation)
        )

        do {
            _ = try await useCase.execute(id: "70")
            XCTFail("Se esperaba cancelación")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }
}

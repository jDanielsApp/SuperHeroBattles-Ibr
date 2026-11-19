import XCTest
@testable import SuperHeroBattle

final class SuperHeroRepositoryTests: XCTestCase {
    func testSearchMapsResultsAndRequestsSearchEndpoint() async throws {
        let client = FakeHTTPClient(outcomes: [.success(TestFixtures.response(TestFixtures.batmanSearchJSON))])
        let repository = try makeRepository(client: client)

        let heroes = try await repository.search(query: "batman")

        XCTAssertEqual(heroes.count, 1)
        XCTAssertEqual(heroes.first?.name, "Batman")
        XCTAssertEqual(heroes.first?.publisher, "DC Comics")

        let requests = await client.requests()
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(
            request.url?.absoluteString,
            "https://api.test/api/test-token/search/batman"
        )
    }

    func testSearchReturnsEmptyWhenAPISaysNotFound() async throws {
        let client = FakeHTTPClient(outcomes: [
            .success(TestFixtures.response(#"{"response":"error","error":"character with given name not found"}"#)),
        ])
        let repository = try makeRepository(client: client)

        let heroes = try await repository.search(query: "unknown")

        XCTAssertTrue(heroes.isEmpty)
    }

    func testSearchReturnsEmptyWhenResultsAreMissingOrEmpty() async throws {
        let missingClient = FakeHTTPClient(outcomes: [
            .success(TestFixtures.response(#"{"response":"success","results-for":"x"}"#)),
        ])
        let emptyClient = FakeHTTPClient(outcomes: [
            .success(TestFixtures.response(#"{"response":"success","results-for":"x","results":[]}"#)),
        ])

        let missing = try await makeRepository(client: missingClient).search(query: "x")
        let empty = try await makeRepository(client: emptyClient).search(query: "x")

        XCTAssertTrue(missing.isEmpty)
        XCTAssertTrue(empty.isEmpty)
    }

    func testSearchPropagatesNonAuthenticationAPIError() async throws {
        let client = FakeHTTPClient(outcomes: [
            .success(TestFixtures.response(#"{"response":"error","error":"temporary maintenance"}"#)),
        ])
        let repository = try makeRepository(client: client)

        do {
            _ = try await repository.search(query: "batman")
            XCTFail("Expected an API error")
        } catch let error as HeroRepositoryError {
            XCTAssertEqual(error, .api(message: "temporary maintenance"))
        }
    }

    func testAPIAccessDeniedIsClassifiedAsUnauthorized() async throws {
        let client = FakeHTTPClient(outcomes: [
            .success(TestFixtures.response(#"{"response":"error","error":"access denied"}"#)),
        ])
        let repository = try makeRepository(client: client)

        do {
            _ = try await repository.search(query: "batman")
            XCTFail("Expected unauthorized error")
        } catch let error as HeroRepositoryError {
            XCTAssertEqual(error, .unauthorized)
        }
    }

    func testAPIInvalidKeyIsClassifiedAsUnauthorized() async throws {
        let client = FakeHTTPClient(outcomes: [
            .success(TestFixtures.response(#"{"response":"error","error":"Invalid API key"}"#)),
        ])
        let repository = try makeRepository(client: client)

        do {
            _ = try await repository.search(query: "batman")
            XCTFail("Expected unauthorized error")
        } catch let error as HeroRepositoryError {
            XCTAssertEqual(error, .unauthorized)
        }
    }

    func testHTTPErrorStatusesAreMapped() async throws {
        try await assertSearchError(statusCode: 401, expected: .unauthorized)
        try await assertSearchError(statusCode: 403, expected: .unauthorized)
        try await assertSearchError(statusCode: 429, expected: .rateLimited)
        try await assertSearchError(statusCode: 500, expected: .server(status: 500))
    }

    func testSearchHTTP404ReturnsEmptyInsteadOfFailing() async throws {
        let client = FakeHTTPClient(outcomes: [
            .success(TestFixtures.response("{}", statusCode: 404)),
        ])
        let repository = try makeRepository(client: client)

        let heroes = try await repository.search(query: "batman")

        XCTAssertTrue(heroes.isEmpty)
    }

    func testInvalidJSONIsMappedToDecodingError() async throws {
        let client = FakeHTTPClient(outcomes: [.success(TestFixtures.response("not json"))])
        let repository = try makeRepository(client: client)

        do {
            _ = try await repository.search(query: "batman")
            XCTFail("Expected a decoding error")
        } catch let error as HeroRepositoryError {
            XCTAssertEqual(error, .decoding)
        }
    }

    func testTransportInvalidResponseAndCancellationArePropagated() async throws {
        let transportClient = FakeHTTPClient(outcomes: [.failure(.transport)])
        let invalidClient = FakeHTTPClient(outcomes: [.failure(.invalidResponse)])
        let cancellationClient = FakeHTTPClient(outcomes: [.cancellation])

        do {
            _ = try await makeRepository(client: transportClient).search(query: "x")
            XCTFail("Expected transport error")
        } catch let error as HeroRepositoryError {
            XCTAssertEqual(error, .transport)
        }

        do {
            _ = try await makeRepository(client: invalidClient).search(query: "x")
            XCTFail("Expected invalid response error")
        } catch let error as HeroRepositoryError {
            XCTAssertEqual(error, .invalidResponse)
        }

        do {
            _ = try await makeRepository(client: cancellationClient).search(query: "x")
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // Correcto: la cancelación no se convierte en error de dominio.
        }
    }

    func testDetailMapsHeroAndRequestsIdentifierEndpoint() async throws {
        let client = FakeHTTPClient(outcomes: [.success(TestFixtures.response(TestFixtures.batmanDetailJSON))])
        let repository = try makeRepository(client: client)

        let hero = try await repository.hero(id: "70")

        XCTAssertEqual(hero.id, "70")
        XCTAssertEqual(hero.name, "Batman")

        let requests = await client.requests()
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(
            request.url?.absoluteString,
            "https://api.test/api/test-token/70"
        )
    }

    func testDetail404AndAPINotFoundBecomeNotFound() async throws {
        let httpClient = FakeHTTPClient(outcomes: [.success(TestFixtures.response("{}", statusCode: 404))])
        let apiClient = FakeHTTPClient(outcomes: [
            .success(TestFixtures.response(#"{"response":"error","error":"character with id 1 not found"}"#)),
        ])

        do {
            _ = try await makeRepository(client: httpClient).hero(id: "1")
            XCTFail("Expected not found")
        } catch let error as HeroRepositoryError {
            XCTAssertEqual(error, .notFound)
        }

        do {
            _ = try await makeRepository(client: apiClient).hero(id: "1")
            XCTFail("Expected not found")
        } catch let error as HeroRepositoryError {
            XCTAssertEqual(error, .notFound)
        }
    }

    func testRepositoryErrorsNeverContainTheToken() async throws {
        let client = FakeHTTPClient(outcomes: [.success(TestFixtures.response("{}", statusCode: 401))])
        let repository = try makeRepository(client: client)

        do {
            _ = try await repository.search(query: "batman")
            XCTFail("Expected unauthorized error")
        } catch {
            XCTAssertFalse(String(describing: error).contains(TestFixtures.token))
        }
    }

    private func makeRepository(client: FakeHTTPClient) throws -> SuperHeroRepository {
        SuperHeroRepository(
            client: SuperHeroAPIClient(
                configuration: try TestFixtures.configuration(),
                httpClient: client
            )
        )
    }

    private func assertSearchError(
        statusCode: Int,
        expected: HeroRepositoryError
    ) async throws {
        let client = FakeHTTPClient(outcomes: [
            .success(TestFixtures.response("{}", statusCode: statusCode)),
        ])
        let repository = try makeRepository(client: client)

        do {
            _ = try await repository.search(query: "batman")
            XCTFail("Expected error for status \(statusCode)")
        } catch let error as HeroRepositoryError {
            XCTAssertEqual(error, expected)
        }
    }
}

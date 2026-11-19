import XCTest
@testable import SuperHeroBattle

final class SuperHeroAPIEndpointTests: XCTestCase {
    func testSearchRequestEncodesQueryAsPathComponent() throws {
        let configuration = try TestFixtures.configuration()
        let endpoint = SuperHeroAPIEndpoint(configuration: configuration)

        let request = endpoint.search(query: "José / spider man")
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(
            url,
            "https://api.test/api/test-token/search/Jos%C3%A9%20%2F%20spider%20man"
        )
    }

    func testSearchRequestSetsHeadersAndPolicy() throws {
        let configuration = try TestFixtures.configuration()
        let endpoint = SuperHeroAPIEndpoint(configuration: configuration)

        let request = endpoint.search(query: "batman")

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(request.timeoutInterval, 15)
        XCTAssertEqual(request.cachePolicy, .reloadIgnoringLocalCacheData)
    }

    func testHeroRequestUsesIdentifierPath() throws {
        let configuration = try TestFixtures.configuration()
        let endpoint = SuperHeroAPIEndpoint(configuration: configuration)

        let request = endpoint.hero(id: "70")

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://api.test/api/test-token/70"
        )
    }

    func testTokenIsNotSentAsAuthorizationHeader() throws {
        let configuration = try TestFixtures.configuration()
        let endpoint = SuperHeroAPIEndpoint(configuration: configuration)

        let request = endpoint.search(query: "batman")

        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }
}

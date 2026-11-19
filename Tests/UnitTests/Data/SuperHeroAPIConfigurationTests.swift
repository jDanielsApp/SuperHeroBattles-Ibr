import XCTest
@testable import SuperHeroBattle

final class SuperHeroAPIConfigurationTests: XCTestCase {
    func testValidConfigurationIsAccepted() throws {
        let configuration = try XCTUnwrap(
            SuperHeroAPIConfiguration(
                baseURLString: " https://superheroapi.com/api ",
                token: " token-123 "
            )
        )

        XCTAssertEqual(configuration.baseURL.absoluteString, "https://superheroapi.com/api")
        XCTAssertEqual(configuration.token, "token-123")
    }

    func testEmptyTokenIsRejected() {
        XCTAssertNil(
            SuperHeroAPIConfiguration(
                baseURLString: "https://superheroapi.com/api",
                token: "   "
            )
        )
    }

    func testBuildSettingPlaceholderIsRejected() {
        XCTAssertNil(
            SuperHeroAPIConfiguration(
                baseURLString: "https://superheroapi.com/api",
                token: "$(SUPERHERO_API_TOKEN)"
            )
        )
    }

    func testExampleTokenIsRejected() {
        XCTAssertNil(
            SuperHeroAPIConfiguration(
                baseURLString: "https://superheroapi.com/api",
                token: "YOUR_SUPERHERO_API_TOKEN"
            )
        )
        XCTAssertNil(
            SuperHeroAPIConfiguration(
                baseURLString: "https://superheroapi.com/api",
                token: "your_superhero_api_token"
            )
        )
    }

    func testQuotedOrEmbeddedBuildSettingPlaceholderIsRejected() {
        XCTAssertNil(
            SuperHeroAPIConfiguration(
                baseURLString: "https://superheroapi.com/api",
                token: "\"$(SUPERHERO_API_TOKEN)\""
            )
        )
        XCTAssertNil(
            SuperHeroAPIConfiguration(
                baseURLString: "https://superheroapi.com/api",
                token: "prefix-$(SUPERHERO_API_TOKEN)"
            )
        )
    }

    func testNonHTTPSBaseURLIsRejected() {
        XCTAssertNil(
            SuperHeroAPIConfiguration(
                baseURLString: "http://superheroapi.com/api",
                token: "token-123"
            )
        )
    }

    func testInvalidBaseURLIsRejected() {
        XCTAssertNil(
            SuperHeroAPIConfiguration(
                baseURLString: "not a url",
                token: "token-123"
            )
        )
    }

    func testConfigurationDoesNotExposeTokenInDescription() throws {
        let configuration = try XCTUnwrap(
            SuperHeroAPIConfiguration(
                baseURLString: "https://superheroapi.com/api",
                token: "secret-token"
            )
        )

        XCTAssertFalse(String(describing: configuration).contains("secret-token"))
    }
}

import XCTest
@testable import SuperHeroBattle

final class SearchQueryNormalizerTests: XCTestCase {
    func testTrimsAndCollapsesWhitespace() {
        XCTAssertEqual(
            SearchQueryNormalizer.normalizedQuery("  spider   man \n"),
            "spider man"
        )
        XCTAssertEqual(
            SearchQueryNormalizer.normalizedQuery("Batman\t\tBeyond"),
            "Batman Beyond"
        )
    }

    func testEmptyAndWhitespaceQueriesNormalizeToEmpty() {
        XCTAssertEqual(SearchQueryNormalizer.normalizedQuery(""), "")
        XCTAssertEqual(SearchQueryNormalizer.normalizedQuery("   \n\t "), "")
    }

    func testNormalizationKeepsCaseAndAccentsForAPI() {
        XCTAssertEqual(
            SearchQueryNormalizer.normalizedQuery("  Bátman  "),
            "Bátman"
        )
    }

    func testCacheKeyIgnoresCaseAndDiacritics() {
        let key = SearchQueryNormalizer.cacheKey("Batman")

        XCTAssertEqual(key, SearchQueryNormalizer.cacheKey("batman"))
        XCTAssertEqual(key, SearchQueryNormalizer.cacheKey("  BÁTMAN  "))
        XCTAssertEqual(key, "batman")
    }

    func testCacheKeyKeepsDifferentQueriesApart() {
        XCTAssertNotEqual(
            SearchQueryNormalizer.cacheKey("batman"),
            SearchQueryNormalizer.cacheKey("batman beyond")
        )
    }
}

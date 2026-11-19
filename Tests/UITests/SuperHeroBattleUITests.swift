import XCTest

final class SuperHeroBattleUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCharacterGuideShowsSearchField() throws {
        let app = XCUIApplication()
        app.launch()

        let guide = app.buttons["home.guide"]
        XCTAssertTrue(guide.waitForExistence(timeout: 5))
        guide.tap()

        XCTAssertTrue(app.textFields["search.field"].waitForExistence(timeout: 5))
    }
}

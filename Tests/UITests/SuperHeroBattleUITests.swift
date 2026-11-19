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

    /// Flujo principal de selección de equipos con fakes: Duelos → 3v3 →
    /// relleno aleatorio de ambos equipos → iniciar combate.
    @MainActor
    func testTeamSelectionRandomFlowReachesCombat() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uitest-fakes"]
        app.launch()

        let duels = app.buttons["home.duels"]
        XCTAssertTrue(duels.waitForExistence(timeout: 5))
        duels.tap()

        let mode = app.buttons["duels.mode.3v3"]
        XCTAssertTrue(mode.waitForExistence(timeout: 5))
        mode.tap()

        for side in ["teamA", "teamB"] {
            for slot in 0..<3 {
                let random = app.buttons["team.slot.random.\(side)-\(slot)"]
                XCTAssertTrue(
                    random.waitForExistence(timeout: 5),
                    "Falta el botón aleatorio de \(side)-\(slot)"
                )
                scrollToHittable(random, in: app)
                random.tap()

                let occupied = app.buttons["team.slot.replace.\(side)-\(slot)"]
                XCTAssertTrue(
                    occupied.waitForExistence(timeout: 10),
                    "El hueco \(side)-\(slot) no se ocupó tras el aleatorio"
                )
            }
        }

        let start = app.buttons["team.selection.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        XCTAssertTrue(start.isEnabled)
        start.tap()

        XCTAssertTrue(
            app.staticTexts["combat.placeholder"].waitForExistence(timeout: 5),
            "No se llegó a la pantalla de combate"
        )
    }

    /// Hace scroll ascendente hasta que el elemento es visible y golpeable.
    @MainActor
    private func scrollToHittable(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 where !element.isHittable {
            app.swipeUp()
        }
    }
}

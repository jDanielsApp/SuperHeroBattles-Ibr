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

        // Regression: the declared accessibility target must be 44×44 pt.
        assertMinimumTarget(app.buttons["search.submit"])
    }

    /// Search flow with fakes: type a query, submit and open a result.
    ///
    /// Launched with the app forced to Spanish while the process language
    /// stays English (`-AppleLanguages (en)`): regression test for the
    /// mixed-language bug, where `L10n.string` answered in the system
    /// language ("Alineación: Bad") instead of the app language.
    @MainActor
    func testSearchFlowOpensResultInAppLanguage() throws {
        let app = XCUIApplication()
        app.launchArguments += [
            "-uitest-fakes",
            "-app.language", "es",
            "-AppleLanguages", "(en)"
        ]
        app.launch()

        let guide = app.buttons["home.guide"]
        XCTAssertTrue(guide.waitForExistence(timeout: 5))
        guide.tap()

        let field = app.textFields["search.field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("Hero 1")

        let submit = app.buttons["search.submit"]
        XCTAssertTrue(submit.waitForExistence(timeout: 5))
        XCTAssertTrue(submit.isEnabled)
        submit.tap()

        // The fixed roster matches "UITest Hero 1" (and 10-12); the
        // exact label pins the first row.
        let firstResult = app.staticTexts["UITest Hero 1"].firstMatch
        XCTAssertTrue(
            firstResult.waitForExistence(timeout: 10),
            "La búsqueda no publicó resultados"
        )
        firstResult.tap()

        // Detail: pushed in compact, pane on the Duo inner screen.
        XCTAssertTrue(
            app.otherElements["hero.detail.powerstats"].waitForExistence(timeout: 5)
                || app.staticTexts["hero.detail.powerstats"].waitForExistence(timeout: 5),
            "No se abrió el detalle del héroe"
        )

        // Regression: the alignment answers in the app language (Spanish),
        // never in the system language ("Bad"/"Good").
        XCTAssertFalse(
            app.staticTexts["Bad"].exists,
            "La alineación respondió en el idioma del sistema"
        )
        XCTAssertFalse(
            app.staticTexts["Good"].exists,
            "La alineación respondió en el idioma del sistema"
        )
        XCTAssertTrue(
            app.staticTexts["Bueno"].exists,
            "La alineación no se localizó al idioma de la app"
        )
    }

    /// Main team selection flow with fakes: Duels → 3v3 →
    /// random fill of both teams → start combat.
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
                assertMinimumTarget(random)
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
            app.staticTexts["combat.narration"].waitForExistence(timeout: 10),
            "No se mostró la narración"
        )
        // The winner and the actual totals are revealed with the published narration.
        XCTAssertTrue(
            app.staticTexts["combat.outcome"].waitForExistence(timeout: 5),
            "No se reveló el ganador tras la narración"
        )
        XCTAssertTrue(
            app.staticTexts["combat.total.teamA"].waitForExistence(timeout: 5),
            "Falta el total del Equipo A"
        )
        XCTAssertTrue(
            app.staticTexts["combat.total.teamB"].waitForExistence(timeout: 5),
            "Falta el total del Equipo B"
        )
        XCTAssertTrue(
            app.staticTexts["combat.narration.source"].waitForExistence(timeout: 5),
            "Falta el badge del origen de la narración"
        )
    }

    /// Flow with fakes: full combat → history with the record →
    /// individual delete from the detail → empty state.
    @MainActor
    func testCombatIsSavedAndDeletableInHistory() throws {
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
                XCTAssertTrue(random.waitForExistence(timeout: 5))
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

        XCTAssertTrue(app.staticTexts["combat.narration"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["combat.outcome"].waitForExistence(timeout: 5))

        // Explicit save: enabled once the narration is published.
        let save = app.buttons["combat.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5), "Falta el botón de guardar")
        XCTAssertTrue(
            waitForEnabled(save, timeout: 10),
            "Guardar no se habilitó tras publicarse la narración"
        )

        save.tap()

        let saveConfirm = app.alerts.buttons["combat.save.confirm"].firstMatch
        XCTAssertTrue(
            saveConfirm.waitForExistence(timeout: 5),
            "El alerta de guardado no se presentó"
        )
        saveConfirm.tap()

        // After saving we return to Home without back taps.
        let history = app.buttons["home.history"]
        XCTAssertTrue(
            history.waitForExistence(timeout: 10),
            "No se volvió a Home tras guardar el combate"
        )
        history.tap()

        let row = app.buttons["history.row"]
        XCTAssertTrue(
            row.waitForExistence(timeout: 10),
            "El combate no se guardó en el historial"
        )

        // The clear-all alert must be presented and cancelled without destroying anything.
        let clear = app.buttons["history.clear"]
        XCTAssertTrue(clear.waitForExistence(timeout: 5))
        clear.tap()

        let clearConfirm = app.alerts.buttons["history.clear.confirm"].firstMatch
        XCTAssertTrue(
            clearConfirm.waitForExistence(timeout: 5),
            "El alerta de vaciado no se presentó"
        )

        app.alerts.buttons["history.clear.cancel"].firstMatch.tap()
        XCTAssertTrue(
            row.waitForExistence(timeout: 5),
            "Cancelar el vaciado no debe borrar el registro"
        )

        // Individual delete: tapping the combat opens its detail.
        row.tap()

        let delete = app.buttons["history.detail.delete"]
        XCTAssertTrue(
            delete.waitForExistence(timeout: 5),
            "Falta el botón de borrado en el detalle del combate"
        )
        delete.tap()

        let deleteConfirm = app.alerts.buttons["history.delete.confirm"].firstMatch
        XCTAssertTrue(
            deleteConfirm.waitForExistence(timeout: 5),
            "El alerta de borrado individual no se presentó"
        )

        // Cancelling keeps the combat in the detail.
        app.alerts.buttons["history.delete.cancel"].firstMatch.tap()
        XCTAssertTrue(
            app.staticTexts["history.detail.outcome"].waitForExistence(timeout: 5),
            "Cancelar el borrado no debe eliminar el registro"
        )

        delete.tap()
        app.alerts.buttons["history.delete.confirm"].firstMatch.tap()

        // After deleting, the detail returns to the empty list.
        let emptyState = app.staticTexts["history.empty"]
        XCTAssertTrue(
            emptyState.waitForExistence(timeout: 10),
            "El historial no quedó vacío tras eliminar el combate"
        )
    }

    /// Smoke test for the detail and settings screens: no business logic,
    /// just verifies they are reachable from the main navigation.
    @MainActor
    func testHeroDetailAndSettingsAreReachable() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uitest-fakes"]
        app.launch()

        // Hero detail from the Guide.
        let guide = app.buttons["home.guide"]
        XCTAssertTrue(guide.waitForExistence(timeout: 5))
        guide.tap()

        // Regression: filter menus declare a 44 pt tall target.
        let publisherFilter = app.descendants(matching: .any)
            .matching(identifier: "guide.filter.publisher").firstMatch
        XCTAssertTrue(
            publisherFilter.waitForExistence(timeout: 10),
            "La barra de filtros no apareció"
        )
        assertMinimumTarget(publisherFilter)

        let firstHero = app.staticTexts["UITest Hero 1"]
        XCTAssertTrue(
            firstHero.waitForExistence(timeout: 10),
            "La Guía no cargó el primer héroe del roster falso"
        )
        firstHero.tap()

        XCTAssertTrue(
            app.otherElements["hero.detail.powerstats"].waitForExistence(timeout: 5)
                || app.staticTexts["hero.detail.powerstats"].waitForExistence(timeout: 5),
            "No se abrió el detalle del héroe"
        )

        // Return to Home by relaunching the app: deterministic in any
        // iPhone Duo pose, where navigation controls are mounted along the
        // side edge and the back button is not always locatable.
        app.terminate()
        app.launch()

        // Settings from the Home bar.
        let settings = app.buttons["home.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["settings.root"].waitForExistence(timeout: 5),
            "No se abrió la pantalla de ajustes"
        )
    }

    /// Smoke test for the saved combat detail in the history.
    @MainActor
    func testHistoryDetailIsReachable() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uitest-fakes"]
        app.launch()

        // Quick 1v1 combat with fakes.
        let duels = app.buttons["home.duels"]
        XCTAssertTrue(duels.waitForExistence(timeout: 5))
        duels.tap()

        let mode = app.buttons["duels.mode.1v1"]
        XCTAssertTrue(mode.waitForExistence(timeout: 5))
        mode.tap()

        for side in ["teamA", "teamB"] {
            let random = app.buttons["team.slot.random.\(side)-0"]
            XCTAssertTrue(random.waitForExistence(timeout: 5))
            random.tap()
            XCTAssertTrue(
                app.buttons["team.slot.replace.\(side)-0"].waitForExistence(timeout: 10)
            )
        }

        let start = app.buttons["team.selection.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()

        XCTAssertTrue(app.staticTexts["combat.narration"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["combat.outcome"].waitForExistence(timeout: 5))

        // Save and return to Home.
        let save = app.buttons["combat.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForEnabled(save, timeout: 10))
        save.tap()
        app.alerts.buttons["combat.save.confirm"].firstMatch.tap()

        let history = app.buttons["home.history"]
        XCTAssertTrue(history.waitForExistence(timeout: 10))
        history.tap()

        // Open the record detail.
        let row = app.buttons["history.row"].firstMatch
        XCTAssertTrue(
            row.waitForExistence(timeout: 10),
            "El combate no se guardó en el historial"
        )
        row.tap()

        XCTAssertTrue(
            app.staticTexts["history.detail.outcome"].waitForExistence(timeout: 5),
            "No se abrió el detalle del combate guardado"
        )
        XCTAssertTrue(
            app.staticTexts["history.detail.narration"].waitForExistence(timeout: 5),
            "Falta la narración en el detalle del combate"
        )
    }

    /// Regression test for the inner screen arrangement: the split is
    /// adaptive (HIG) — teams side by side in landscape and stacked in
    /// portrait. The 600 pt threshold separates the suite's destinations:
    /// iPhone (compact) and the Duo inner screen (regular).
    @MainActor
    func testTeamSelectionPanelsMatchWindowSizeClass() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uitest-fakes"]
        app.launch()

        let duels = app.buttons["home.duels"]
        XCTAssertTrue(duels.waitForExistence(timeout: 5))
        duels.tap()

        let mode = app.buttons["duels.mode.1v1"]
        XCTAssertTrue(mode.waitForExistence(timeout: 5))
        mode.tap()

        let teamARandom = app.buttons["team.slot.random.teamA-0"]
        let teamBRandom = app.buttons["team.slot.random.teamB-0"]
        XCTAssertTrue(
            teamARandom.waitForExistence(timeout: 5),
            "Falta el botón aleatorio del Equipo A"
        )
        XCTAssertTrue(
            teamBRandom.waitForExistence(timeout: 5),
            "Falta el botón aleatorio del Equipo B"
        )

        let window = app.windows.firstMatch.frame
        let isRegular = window.width >= 600
        let isLandscape = window.width > window.height

        if isRegular, isLandscape {
            // Duo open in landscape: Team A on the left, B on the right.
            XCTAssertGreaterThanOrEqual(
                teamBRandom.frame.minX + 1,
                teamARandom.frame.maxX,
                "En el Duo abierto en horizontal los equipos deben quedar lado a lado"
            )
        } else {
            // Compact or Duo open in portrait: A on top, B below.
            XCTAssertGreaterThanOrEqual(
                teamBRandom.frame.minY + 1,
                teamARandom.frame.maxY,
                "En compact o en vertical el Equipo B debe quedar bajo el Equipo A"
            )
        }
    }

    /// Regression for sub-44pt declared targets: the accessibility frame
    /// must be at least 44×44 pt so Voice Control and Switch Control hit
    /// the control reliably. Finger taps are not enough evidence.
    @MainActor
    private func assertMinimumTarget(_ element: XCUIElement) {
        XCTAssertGreaterThanOrEqual(
            element.frame.width,
            44,
            "\(element) declara un ancho menor que 44 pt"
        )
        XCTAssertGreaterThanOrEqual(
            element.frame.height,
            44,
            "\(element) declara una altura menor que 44 pt"
        )
    }

    /// Waits until an existing element is enabled.
    @MainActor
    private func waitForEnabled(
        _ element: XCUIElement,
        timeout: TimeInterval
    ) -> Bool {
        let enabled = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isEnabled == true"),
            object: element
        )
        return XCTWaiter.wait(for: [enabled], timeout: timeout) == .completed
    }

    /// Scrolls up until the element is visible and hittable.
    @MainActor
    private func scrollToHittable(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 where !element.isHittable {
            app.swipeUp()
        }
    }
}

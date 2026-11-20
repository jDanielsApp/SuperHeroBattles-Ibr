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
            app.staticTexts["combat.narration"].waitForExistence(timeout: 10),
            "No se mostró la narración"
        )
        // El ganador y los totales reales se revelan con la narración publicada.
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

    /// Flujo con fakes: combate completo → historial con el registro →
    /// borrado individual → estado vacío.
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

        // Guardado explícito: habilitado con la narración publicada.
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

        // Tras guardar volvemos a Home sin back-taps.
        let history = app.buttons["home.history"]
        XCTAssertTrue(
            history.waitForExistence(timeout: 10),
            "No se volvió a Home tras guardar el combate"
        )
        history.tap()

        XCTAssertTrue(
            app.buttons["history.delete"].waitForExistence(timeout: 10),
            "El combate no se guardó en el historial"
        )

        // El alerta de vaciado debe presentarse y cancelar sin destruir nada.
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
            app.buttons["history.delete"].waitForExistence(timeout: 5),
            "Cancelar el vaciado no debe borrar el registro"
        )

        // El alerta de borrado individual: cancelar conserva, confirmar vacía.
        app.buttons["history.delete"].firstMatch.tap()

        let deleteConfirm = app.alerts.buttons["history.delete.confirm"].firstMatch
        XCTAssertTrue(
            deleteConfirm.waitForExistence(timeout: 5),
            "El alerta de borrado individual no se presentó"
        )

        app.alerts.buttons["history.delete.cancel"].firstMatch.tap()
        XCTAssertTrue(
            app.buttons["history.delete"].waitForExistence(timeout: 5),
            "Cancelar el borrado no debe eliminar el registro"
        )

        app.buttons["history.delete"].firstMatch.tap()
        app.alerts.buttons["history.delete.confirm"].firstMatch.tap()

        let emptyState = app.staticTexts["history.empty"]
        XCTAssertTrue(
            emptyState.waitForExistence(timeout: 10),
            "El historial no quedó vacío tras eliminar el combate"
        )
    }

    /// Smoke test de pantallas de detalle y ajustes: sin lógica de negocio,
    /// solo verifica que son alcanzables desde la navegación principal.
    @MainActor
    func testHeroDetailAndSettingsAreReachable() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uitest-fakes"]
        app.launch()

        // Detalle de héroe desde la Guía.
        let guide = app.buttons["home.guide"]
        XCTAssertTrue(guide.waitForExistence(timeout: 5))
        guide.tap()

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

        // Volver a Home: dos niveles atrás (detalle → Guía → Home).
        for _ in 0..<2 {
            let back = app.navigationBars.buttons.element(boundBy: 0)
            XCTAssertTrue(back.waitForExistence(timeout: 5))
            back.tap()
        }

        // Ajustes desde la barra de Home.
        let settings = app.buttons["home.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["settings.root"].waitForExistence(timeout: 5),
            "No se abrió la pantalla de ajustes"
        )
    }

    /// Smoke test del detalle de combate guardado en el historial.
    @MainActor
    func testHistoryDetailIsReachable() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uitest-fakes"]
        app.launch()

        // Combate 1v1 rápido con fakes.
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

        // Guardar y volver a Home.
        let save = app.buttons["combat.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForEnabled(save, timeout: 10))
        save.tap()
        app.alerts.buttons["combat.save.confirm"].firstMatch.tap()

        let history = app.buttons["home.history"]
        XCTAssertTrue(history.waitForExistence(timeout: 10))
        history.tap()

        // Abrir el detalle del registro.
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

    /// Espera a que un elemento existente esté habilitado.
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

    /// Hace scroll ascendente hasta que el elemento es visible y golpeable.
    @MainActor
    private func scrollToHittable(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 where !element.isHittable {
            app.swipeUp()
        }
    }
}

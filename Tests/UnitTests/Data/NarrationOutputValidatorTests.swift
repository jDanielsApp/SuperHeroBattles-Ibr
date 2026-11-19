import XCTest
@testable import SuperHeroBattle

final class NarrationOutputValidatorTests: XCTestCase {
    func testValidBeatsJoinIntoParagraphs() throws {
        let narration = makeNarration(
            opening: "Equipo A y Equipo B se miden en la arena.",
            verdict: "El veredicto es claro: gana Equipo A."
        )

        let text = try NarrationOutputValidator.validatedText(
            from: narration,
            context: makeContext(.winner(.teamA)),
            language: .spanish
        )

        XCTAssertEqual(
            text,
            "Equipo A y Equipo B se miden en la arena.\n\n"
                + "Intercambio.\n\nClímax.\n\n"
                + "El veredicto es claro: gana Equipo A."
        )
    }

    func testEmptyBeatThrowsInvalidResponse() {
        let narration = makeNarration(opening: "   ")

        XCTAssertThrowsError(
            try NarrationOutputValidator.validatedText(
                from: narration,
                context: makeContext(.winner(.teamA)),
                language: .spanish
            )
        ) { error in
            XCTAssertEqual(error as? NarrationError, .invalidResponse)
        }
    }

    func testMissingTeamThrowsInvalidResponse() {
        let narration = makeNarration(
            opening: "Solo aparece el Equipo A en esta narración.",
            verdict: "Gana Equipo A."
        )

        XCTAssertThrowsError(
            try NarrationOutputValidator.validatedText(
                from: narration,
                context: makeContext(.winner(.teamA)),
                language: .spanish
            )
        ) { error in
            XCTAssertEqual(error as? NarrationError, .invalidResponse)
        }
    }

    func testWinnerMissingFromVerdictThrowsInvalidResponse() {
        // El Equipo A solo aparece en la apertura: el veredicto nombra al B.
        let narration = makeNarration(
            opening: "Equipo A contra Equipo B.",
            verdict: "El bando B se impone."
        )

        XCTAssertThrowsError(
            try NarrationOutputValidator.validatedText(
                from: narration,
                context: makeContext(.winner(.teamA)),
                language: .spanish
            )
        ) { error in
            XCTAssertEqual(error as? NarrationError, .invalidResponse)
        }
    }

    func testDrawDoesNotRequireWinnerInVerdict() throws {
        let narration = makeNarration(
            opening: "Equipo A contra Equipo B.",
            verdict: "Nadie cede: empate total."
        )

        let text = try NarrationOutputValidator.validatedText(
            from: narration,
            context: makeContext(.draw),
            language: .spanish
        )

        XCTAssertTrue(text.contains("empate total"))
    }

    func testTeamNamesAreCaseInsensitive() throws {
        let narration = makeNarration(
            opening: "el equipo A se enfrenta al EQUIPO b.",
            verdict: "al final domina el equipo A."
        )

        XCTAssertNoThrow(
            try NarrationOutputValidator.validatedText(
                from: narration,
                context: makeContext(.winner(.teamA)),
                language: .spanish
            )
        )
    }

    func testEnglishNarrationValidatesWithEnglishTeamNames() throws {
        let narration = makeNarration(
            opening: "Team A clashes against Team B.",
            verdict: "Team A takes it."
        )

        XCTAssertNoThrow(
            try NarrationOutputValidator.validatedText(
                from: narration,
                context: makeContext(.winner(.teamA)),
                language: .english
            )
        )
    }

    // MARK: - Helpers

    private func makeNarration(
        opening: String = "Apertura.",
        exchange: String = "Intercambio.",
        climax: String = "Clímax.",
        verdict: String = "Veredicto."
    ) -> GeneratedNarration {
        GeneratedNarration(
            opening: opening,
            exchange: exchange,
            climax: climax,
            verdict: verdict
        )
    }

    private func makeContext(_ outcome: CombatOutcome) -> NarrationContext {
        switch outcome {
        case .draw:
            let hero = Hero(id: "1", name: "Batman", powerStats: PowerStats(intelligence: 50))
            let participants = BattleParticipants(mode: .oneVsOne, teamA: [hero], teamB: [hero])
            let result = CombatEngine(luckProvider: SequenceLuckProvider([7, 7]))
                .resolve(participants)
            return NarrationContext(result: result, participants: participants)
        case .winner:
            let participants = BattleParticipants(
                mode: .oneVsOne,
                teamA: [Hero(id: "1", name: "Batman", powerStats: PowerStats(intelligence: 100))],
                teamB: [Hero(id: "2", name: "Joker", powerStats: PowerStats(intelligence: 70))]
            )
            let result = CombatEngine(luckProvider: SequenceLuckProvider([40, 7]))
                .resolve(participants)
            return NarrationContext(result: result, participants: participants)
        }
    }
}

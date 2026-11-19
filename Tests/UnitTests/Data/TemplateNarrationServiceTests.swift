import XCTest
@testable import SuperHeroBattle

final class TemplateNarrationServiceTests: XCTestCase {
    func testNarrativeIsDeterministicAndDeclaresTemplateSource() async throws {
        let service = TemplateNarrationService()

        let first = try await service.narrate(
            result: makeResult(),
            participants: makeParticipants(),
            language: .spanish
        )
        let second = try await service.narrate(
            result: makeResult(),
            participants: makeParticipants(),
            language: .spanish
        )

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.source, .template)
    }

    func testSpanishNarrativeContainsWinnerTeamsAndNames() async throws {
        let service = TemplateNarrationService()

        let narrative = try await service.narrate(
            result: makeResult(),
            participants: makeParticipants(),
            language: .spanish
        )

        XCTAssertEqual(narrative.source, .template)
        XCTAssertTrue(narrative.text.contains("Equipo A"))
        XCTAssertTrue(narrative.text.contains("Equipo B"))
        XCTAssertTrue(narrative.text.contains("Batman"))
        XCTAssertTrue(narrative.text.contains("Joker"))
        XCTAssertTrue(narrative.text.contains("Ganador: Equipo A"))
    }

    func testEnglishNarrativeIsLocalized() async throws {
        let service = TemplateNarrationService()

        let narrative = try await service.narrate(
            result: makeResult(),
            participants: makeParticipants(),
            language: .english
        )

        XCTAssertTrue(narrative.text.contains("Team A"))
        XCTAssertTrue(narrative.text.contains("Team B"))
        XCTAssertTrue(narrative.text.contains("Winner: Team A"))
        XCTAssertFalse(narrative.text.contains("Ganador"))
    }

    func testProperNamesAreNeverTranslated() async throws {
        let service = TemplateNarrationService()

        let spanish = try await service.narrate(
            result: makeResult(),
            participants: makeParticipants(),
            language: .spanish
        )
        let english = try await service.narrate(
            result: makeResult(),
            participants: makeParticipants(),
            language: .english
        )

        XCTAssertTrue(spanish.text.contains("Batman"))
        XCTAssertTrue(english.text.contains("Batman"))
    }

    func testDrawNarrativeDeclaresDraw() async throws {
        let engine = CombatEngine(luckProvider: SequenceLuckProvider([7, 7]))
        let hero = Hero(id: "1", name: "Batman")
        let result = engine.resolve(
            BattleParticipants(mode: .oneVsOne, teamA: [hero], teamB: [hero])
        )

        let narrative = try await TemplateNarrationService().narrate(
            result: result,
            participants: BattleParticipants(mode: .oneVsOne, teamA: [hero], teamB: [hero]),
            language: .spanish
        )

        XCTAssertTrue(narrative.text.contains("empate"))
    }

    func testAvailabilityIsAlwaysAvailable() async {
        let availability = await TemplateNarrationService().availability

        XCTAssertEqual(availability, .available)
    }

    // MARK: - Helpers

    private func makeParticipants() -> BattleParticipants {
        BattleParticipants(
            mode: .oneVsOne,
            teamA: [Hero(id: "1", name: "Batman")],
            teamB: [Hero(id: "2", name: "Joker")]
        )
    }

    private func makeResult() -> CombatResult {
        CombatEngine(luckProvider: SequenceLuckProvider([40, 20]))
            .resolve(makeParticipants())
    }
}

import XCTest
@testable import SuperHeroBattle

/// Regression tests for the mixed-language bug: strings resolved through
/// `L10n.string` must honor the requested (app) locale, never the
/// system locale that `.current` would pick.
final class LocalizedOutcomeTextsTests: XCTestCase {
    private let english = Locale(identifier: "en")
    private let spanish = Locale(identifier: "es")

    // MARK: - History row

    func testHistoryWinnerTextHonorsRequestedLocale() {
        XCTAssertEqual(
            HistoryOutcomeText.text(for: .winner(.teamA), locale: spanish),
            "Ganador: Equipo A"
        )
        XCTAssertEqual(
            HistoryOutcomeText.text(for: .winner(.teamB), locale: spanish),
            "Ganador: Equipo B"
        )
        XCTAssertEqual(
            HistoryOutcomeText.text(for: .winner(.teamA), locale: english),
            "Winner: Team A"
        )
    }

    func testHistoryDrawTextHonorsRequestedLocale() {
        XCTAssertEqual(
            HistoryOutcomeText.text(for: .draw, locale: spanish),
            "¡Empate!"
        )
        XCTAssertEqual(
            HistoryOutcomeText.text(for: .draw, locale: english),
            "It's a draw"
        )
    }

    // MARK: - Team slot VoiceOver value

    func testTeamSlotContextHonorsRequestedLocale() {
        XCTAssertEqual(
            TeamSlotView.slotContext(side: .teamA, slot: 0, locale: spanish),
            "Equipo A, 1"
        )
        XCTAssertEqual(
            TeamSlotView.slotContext(side: .teamB, slot: 2, locale: english),
            "Team B, 3"
        )
    }

    // MARK: - Hero detail alignment

    func testHeroAlignmentTextHonorsRequestedLocale() {
        XCTAssertEqual(
            HeroDetailView.alignmentText(.bad, locale: spanish),
            "Malvado"
        )
        XCTAssertEqual(
            HeroDetailView.alignmentText(.good, locale: spanish),
            "Bueno"
        )
        XCTAssertEqual(
            HeroDetailView.alignmentText(.bad, locale: english),
            "Bad"
        )
        XCTAssertEqual(
            HeroDetailView.alignmentText(.unknown, locale: spanish),
            "Desconocido"
        )
    }
}

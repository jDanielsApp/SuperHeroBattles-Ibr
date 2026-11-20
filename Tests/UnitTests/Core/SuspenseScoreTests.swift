import XCTest
@testable import SuperHeroBattle

final class SuspenseScoreTests: XCTestCase {
    func testRevealedStateAlwaysShowsTheRealScore() {
        XCTAssertEqual(
            SuspenseScore.decision(isRevealed: true, reduceMotion: false),
            .revealed
        )
        XCTAssertEqual(
            SuspenseScore.decision(isRevealed: true, reduceMotion: true),
            .revealed
        )
    }

    func testSuspenseCyclesWithoutReduceMotion() {
        XCTAssertEqual(
            SuspenseScore.decision(isRevealed: false, reduceMotion: false),
            .cyclingMystery
        )
    }

    func testSuspenseFreezesWithReduceMotion() {
        XCTAssertEqual(
            SuspenseScore.decision(isRevealed: false, reduceMotion: true),
            .staticMystery
        )
    }

    func testMysteryValueStaysWithinTheRequestedRange() {
        for _ in 0..<500 {
            let value = SuspenseScore.randomMystery(in: SuspenseScore.combatantRange)
            XCTAssertTrue(
                SuspenseScore.combatantRange.contains(value),
                "Marcador aleatorio fuera de rango: \(value)"
            )
        }
    }

    func testTeamRangeScalesWithTeamSize() {
        XCTAssertEqual(SuspenseScore.teamRange(forTeamSize: 1), 12...239)
        XCTAssertEqual(SuspenseScore.teamRange(forTeamSize: 2), 24...379)
        XCTAssertEqual(SuspenseScore.teamRange(forTeamSize: 3), 36...519)
    }

    func testTeamRangeNeverCollapsesForInvalidSizes() {
        XCTAssertEqual(SuspenseScore.teamRange(forTeamSize: 0), 12...239)
        XCTAssertEqual(SuspenseScore.teamRange(forTeamSize: -3), 12...239)
    }
}

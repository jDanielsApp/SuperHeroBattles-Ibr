import XCTest
@testable import SuperHeroBattle

final class NarrationContextTests: XCTestCase {
    func testLabelsEveryCombatantWithItsSide() {
        let context = makeContext(
            teamAStats: PowerStats(intelligence: 100),
            teamBStats: PowerStats(intelligence: 70)
        )

        XCTAssertEqual(context.heroes.map(\.side), [.teamA, .teamB])
        XCTAssertEqual(context.heroes(in: .teamA).map(\.hero.name), ["Batman"])
        XCTAssertEqual(context.heroes(in: .teamB).map(\.hero.name), ["Joker"])
    }

    func testSameHeroInBothTeamsStaysLabeledPerSide() {
        let hero = Hero(id: "1", name: "Batman")
        let participants = BattleParticipants(mode: .oneVsOne, teamA: [hero], teamB: [hero])
        let result = CombatEngine(luckProvider: SequenceLuckProvider([7, 7]))
            .resolve(participants)

        let context = NarrationContext(result: result, participants: participants)

        XCTAssertEqual(context.heroes.count, 2)
        XCTAssertEqual(context.heroes.map(\.side), [.teamA, .teamB])
        XCTAssertEqual(context.heroes.map(\.hero.name), ["Batman", "Batman"])
        XCTAssertEqual(context.heroes.map(\.luck), [7, 7], "Tiradas independientes por bando")
    }

    func testClearWinBoundaryIsExactlyThirty() {
        // 100 + 7 = 107 vs 70 + 7 = 77: an exact gap of 30.
        let boundary = makeContext(
            teamAStats: PowerStats(intelligence: 100),
            teamBStats: PowerStats(intelligence: 70)
        )
        // 99 + 7 = 106 vs 77: a gap of 29.
        let close = makeContext(
            teamAStats: PowerStats(intelligence: 99),
            teamBStats: PowerStats(intelligence: 70)
        )

        XCTAssertEqual(boundary.gap, 30)
        XCTAssertTrue(boundary.isClearWin, "30 exacto cuenta como victoria clara")
        XCTAssertEqual(close.gap, 29)
        XCTAssertFalse(close.isClearWin)
    }

    func testDrawHasNoGap() {
        let hero = Hero(id: "1", name: "Batman", powerStats: PowerStats(intelligence: 50))
        let participants = BattleParticipants(mode: .oneVsOne, teamA: [hero], teamB: [hero])
        let result = CombatEngine(luckProvider: SequenceLuckProvider([7, 7]))
            .resolve(participants)

        let context = NarrationContext(result: result, participants: participants)

        XCTAssertEqual(context.outcome, .draw)
        XCTAssertEqual(context.gap, 0)
        XCTAssertFalse(context.isClearWin)
    }

    func testKeepsAffinityBonusesPerTeam() {
        let teamA = [
            Hero(id: "1", name: "Batman", affiliation: "Justice League"),
            Hero(id: "2", name: "Robin", affiliation: "Justice League")
        ]
        let teamB = [Hero(id: "3", name: "Joker"), Hero(id: "4", name: "Harley Quinn")]
        let participants = BattleParticipants(mode: .twoVsTwo, teamA: teamA, teamB: teamB)
        let result = CombatEngine(luckProvider: SequenceLuckProvider([7, 7, 7, 7]))
            .resolve(participants)

        let context = NarrationContext(result: result, participants: participants)

        XCTAssertEqual(context.teamABonuses.count, 1)
        XCTAssertTrue(context.teamBBonuses.isEmpty)
        XCTAssertEqual(context.heroName(id: "2"), "Robin")
    }

    // MARK: - Helpers

    private func makeContext(
        teamAStats: PowerStats,
        teamBStats: PowerStats
    ) -> NarrationContext {
        let participants = BattleParticipants(
            mode: .oneVsOne,
            teamA: [Hero(id: "1", name: "Batman", powerStats: teamAStats)],
            teamB: [Hero(id: "2", name: "Joker", powerStats: teamBStats)]
        )
        let result = CombatEngine(luckProvider: SequenceLuckProvider([7, 7]))
            .resolve(participants)

        return NarrationContext(result: result, participants: participants)
    }
}

private extension Hero {
    init(id: String, name: String, affiliation: String? = nil, powerStats: PowerStats = PowerStats()) {
        self.init(
            id: id,
            name: name,
            connections: HeroConnections(groupAffiliation: affiliation),
            powerStats: powerStats
        )
    }
}

import XCTest
@testable import SuperHeroBattle

final class CombatEngineTests: XCTestCase {
    func testKnownStatsAverageIntoBaseAndLuckAddsToTotal() {
        let engine = CombatEngine(luckProvider: SequenceLuckProvider([40, 40]))
        let participants = BattleParticipants(
            mode: .oneVsOne,
            teamA: [makeHero(id: "1", stats: PowerStats(intelligence: 70))],
            teamB: [makeHero(id: "2", stats: PowerStats(strength: 70))]
        )

        let result = engine.resolve(participants)

        XCTAssertEqual(result.teamA.combatants[0].baseScore, 70)
        XCTAssertEqual(result.teamA.combatants[0].luck, 40)
        XCTAssertEqual(result.teamA.combatants[0].totalScore, 110)
    }

    func testUnknownStatsAreExcludedFromBase() {
        let engine = CombatEngine(luckProvider: SequenceLuckProvider([10, 10]))
        let participants = BattleParticipants(
            mode: .oneVsOne,
            teamA: [makeHero(id: "1", stats: PowerStats(intelligence: 100, strength: nil, speed: nil, durability: nil, power: nil, combat: nil))],
            teamB: [makeHero(id: "2", stats: PowerStats())]
        )

        let result = engine.resolve(participants)

        XCTAssertEqual(result.teamA.combatants[0].baseScore, 100)
        XCTAssertEqual(result.teamB.combatants[0].baseScore, 0)
        XCTAssertEqual(result.teamB.combatants[0].totalScore, 10)
    }

    func testLuckIsDrawnPerCombatantInSlotOrder() {
        let engine = CombatEngine(luckProvider: SequenceLuckProvider([7, 77, 50, 50]))
        let participants = BattleParticipants(
            mode: .twoVsTwo,
            teamA: [makeHero(id: "1"), makeHero(id: "2")],
            teamB: [makeHero(id: "3"), makeHero(id: "4")]
        )

        let result = engine.resolve(participants)

        XCTAssertEqual(result.teamA.combatants.map(\.luck), [7, 77])
        XCTAssertEqual(result.teamB.combatants.map(\.luck), [50, 50])
    }

    func testSameHeroInBothTeamsDrawsIndependentLuck() {
        let engine = CombatEngine(luckProvider: SequenceLuckProvider([10, 20]))
        let hero = makeHero(id: "7")
        let participants = BattleParticipants(mode: .oneVsOne, teamA: [hero], teamB: [hero])

        let result = engine.resolve(participants)

        XCTAssertEqual(result.teamA.combatants[0].luck, 10)
        XCTAssertEqual(result.teamB.combatants[0].luck, 20)
    }

    func testFeelingAddsThirtyThreePerMatchingPair() {
        let engine = CombatEngine(luckProvider: SequenceLuckProvider([7, 7, 7, 7]))
        let participants = BattleParticipants(
            mode: .twoVsTwo,
            teamA: [
                makeHero(id: "1", affiliation: "Justice League"),
                makeHero(id: "2", affiliation: "Justice League")
            ],
            teamB: [makeHero(id: "3"), makeHero(id: "4")]
        )

        let result = engine.resolve(participants)

        XCTAssertEqual(result.teamA.affinityBonuses.count, 1)
        XCTAssertEqual(result.teamA.affinityBonuses[0].bonus, 33)
        XCTAssertTrue(result.teamB.affinityBonuses.isEmpty)
    }

    func testOneOnOneHasNoPairsEvenWithSharedAffiliation() {
        let engine = CombatEngine(luckProvider: SequenceLuckProvider([7, 7]))
        let participants = BattleParticipants(
            mode: .oneVsOne,
            teamA: [makeHero(id: "1", affiliation: "Justice League")],
            teamB: [makeHero(id: "1", affiliation: "Justice League")]
        )

        let result = engine.resolve(participants)

        XCTAssertTrue(result.teamA.affinityBonuses.isEmpty)
        XCTAssertTrue(result.teamB.affinityBonuses.isEmpty)
    }

    func testThreeWayTeamHasThreePairs() {
        let engine = CombatEngine(
            luckProvider: SequenceLuckProvider([7, 7, 7, 7, 7, 7])
        )
        let team = (1...3).map {
            makeHero(id: String($0), affiliation: "Justice League")
        }
        let participants = BattleParticipants(
            mode: .threeVsThree,
            teamA: team,
            teamB: (4...6).map { makeHero(id: String($0)) }
        )

        let result = engine.resolve(participants)

        XCTAssertEqual(result.teamA.affinityBonuses.count, 3)
        XCTAssertEqual(result.teamA.affinityBonuses.map(\.bonus), [33, 33, 33])
        XCTAssertEqual(result.teamA.affinityBonuses.map(\.bonus).reduce(0, +), 99)
    }

    func testFeelingNeverCrossesTeams() {
        let engine = CombatEngine(luckProvider: SequenceLuckProvider([7, 7, 7, 7]))
        let participants = BattleParticipants(
            mode: .twoVsTwo,
            teamA: [
                makeHero(id: "1", affiliation: "Justice League"),
                makeHero(id: "2")
            ],
            teamB: [
                makeHero(id: "3", affiliation: "Justice League"),
                makeHero(id: "4")
            ]
        )

        let result = engine.resolve(participants)

        XCTAssertTrue(result.teamA.affinityBonuses.isEmpty)
        XCTAssertTrue(result.teamB.affinityBonuses.isEmpty)
    }

    func testTeamTotalSumsIndividualsAndFeeling() {
        let engine = CombatEngine(luckProvider: SequenceLuckProvider([40, 25, 7, 7]))
        let participants = BattleParticipants(
            mode: .twoVsTwo,
            teamA: [
                makeHero(id: "1", stats: PowerStats(intelligence: 70), affiliation: "Justice League"),
                makeHero(id: "2", stats: PowerStats(intelligence: 85), affiliation: "Justice League")
            ],
            teamB: [makeHero(id: "3"), makeHero(id: "4")]
        )

        let result = engine.resolve(participants)

        // 70 + 40 + 85 + 25 + 33 = 253
        XCTAssertEqual(result.teamA.totalScore, 253)
    }

    func testHigherTotalWins() {
        let engine = CombatEngine(luckProvider: SequenceLuckProvider([7, 7]))
        let participants = BattleParticipants(
            mode: .oneVsOne,
            teamA: [makeHero(id: "1", stats: PowerStats(intelligence: 90))],
            teamB: [makeHero(id: "2", stats: PowerStats(intelligence: 10))]
        )

        let result = engine.resolve(participants)

        XCTAssertEqual(result.outcome, .winner(.teamA))
    }

    func testEqualTotalsDeclareDrawWithoutExtraRolls() {
        let engine = CombatEngine(luckProvider: SequenceLuckProvider([7, 7]))
        let hero = makeHero(id: "1", stats: PowerStats(intelligence: 50))
        let participants = BattleParticipants(mode: .oneVsOne, teamA: [hero], teamB: [hero])

        let result = engine.resolve(participants)

        XCTAssertEqual(result.outcome, .draw)
        XCTAssertEqual(result.teamA.totalScore, result.teamB.totalScore)
    }

    func testResultIsFullyTraceable() {
        // Réplica del ejemplo conceptual de la especificación con las reglas
        // reales: tres parejas a 33 puntos suman 99, no 66.
        let engine = CombatEngine(
            luckProvider: SequenceLuckProvider([40, 25, 50, 7, 7, 7])
        )
        let teamA = [
            makeHero(id: "1", stats: PowerStats(intelligence: 70), affiliation: "Justice League"),
            makeHero(id: "2", stats: PowerStats(intelligence: 85), affiliation: "Justice League"),
            makeHero(id: "3", stats: PowerStats(intelligence: 90), affiliation: "Justice League")
        ]
        let participants = BattleParticipants(
            mode: .threeVsThree,
            teamA: teamA,
            teamB: (4...6).map { makeHero(id: String($0)) }
        )

        let result = engine.resolve(participants)

        let combatantA = result.teamA.combatants
        XCTAssertEqual(combatantA.map(\.baseScore), [70, 85, 90])
        XCTAssertEqual(combatantA.map(\.luck), [40, 25, 50])
        XCTAssertEqual(combatantA.map(\.totalScore), [110, 110, 140])
        XCTAssertEqual(result.teamA.affinityBonuses.count, 3)
        XCTAssertEqual(
            result.teamA.totalScore,
            110 + 110 + 140 + 99,
            accuracy: 0.001
        )
        XCTAssertEqual(result.mode, .threeVsThree)
        XCTAssertEqual(result.outcome, .winner(.teamA))
    }

    func testSystemLuckStaysWithinRange() {
        let provider = SystemLuckProvider()

        for _ in 0..<500 {
            let luck = provider.nextLuck()
            XCTAssertTrue((7...77).contains(luck), "Suerte fuera de rango: \(luck)")
        }
    }

    private func makeHero(
        id: String,
        stats: PowerStats = PowerStats(),
        affiliation: String? = nil
    ) -> Hero {
        Hero(
            id: id,
            name: "Hero \(id)",
            biography: HeroBiography(publisher: "DC Comics"),
            connections: HeroConnections(groupAffiliation: affiliation),
            powerStats: stats
        )
    }
}

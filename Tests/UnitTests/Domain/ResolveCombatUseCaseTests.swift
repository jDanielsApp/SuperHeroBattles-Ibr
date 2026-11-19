import XCTest
@testable import SuperHeroBattle

final class ResolveCombatUseCaseTests: XCTestCase {
    func testDelegatesToEngineWithoutAlteringParticipants() {
        let luckProvider = SequenceLuckProvider([7, 7])
        let engine = CombatEngine(luckProvider: luckProvider)
        let useCase = ResolveCombatUseCase(engine: engine)
        let participants = BattleParticipants(
            mode: .oneVsOne,
            teamA: [makeHero(id: "1", intelligence: 90)],
            teamB: [makeHero(id: "2", intelligence: 10)]
        )

        let result = useCase.execute(participants: participants)

        XCTAssertEqual(result, engine.resolve(participants))
        XCTAssertEqual(result.outcome, .winner(.teamA))
        XCTAssertEqual(participants.teamA.map(\.id), ["1"])
        XCTAssertEqual(participants.teamB.map(\.id), ["2"])
    }

    private func makeHero(id: String, intelligence: Int) -> Hero {
        Hero(
            id: id,
            name: "Hero \(id)",
            powerStats: PowerStats(intelligence: intelligence)
        )
    }
}

import XCTest
@testable import SuperHeroBattle

final class BuildBattleParticipantsUseCaseTests: XCTestCase {
    private let useCase = BuildBattleParticipantsUseCase()

    func testCompleteDraftsBuildParticipantsInSlotOrder() throws {
        var teamA = TeamDraft(side: .teamA, mode: .twoVsTwo)
        var teamB = TeamDraft(side: .teamB, mode: .twoVsTwo)
        try teamA.assign(makeHero(id: "10"), at: 0)
        try teamA.assign(makeHero(id: "20"), at: 1)
        try teamB.assign(makeHero(id: "30"), at: 0)
        try teamB.assign(makeHero(id: "40"), at: 1)

        let participants = try useCase.execute(teamA: teamA, teamB: teamB)

        XCTAssertEqual(participants.mode, .twoVsTwo)
        XCTAssertEqual(participants.teamA.map(\.id), ["10", "20"])
        XCTAssertEqual(participants.teamB.map(\.id), ["30", "40"])
    }

    func testIncompleteTeamAThrowsNamingTheSide() throws {
        var teamA = TeamDraft(side: .teamA, mode: .oneVsOne)
        var teamB = TeamDraft(side: .teamB, mode: .oneVsOne)
        try teamB.assign(makeHero(id: "2"), at: 0)

        XCTAssertThrowsError(try useCase.execute(teamA: teamA, teamB: teamB)) { error in
            XCTAssertEqual(error as? BattleParticipantsError, .incompleteTeam(.teamA))
        }
    }

    func testIncompleteTeamBThrowsNamingTheSide() throws {
        var teamA = TeamDraft(side: .teamA, mode: .oneVsOne)
        var teamB = TeamDraft(side: .teamB, mode: .oneVsOne)
        try teamA.assign(makeHero(id: "1"), at: 0)

        XCTAssertThrowsError(try useCase.execute(teamA: teamA, teamB: teamB)) { error in
            XCTAssertEqual(error as? BattleParticipantsError, .incompleteTeam(.teamB))
        }
    }

    func testMismatchedModesThrow() throws {
        var teamA = TeamDraft(side: .teamA, mode: .oneVsOne)
        var teamB = TeamDraft(side: .teamB, mode: .twoVsTwo)
        try teamA.assign(makeHero(id: "1"), at: 0)
        try teamB.assign(makeHero(id: "2"), at: 0)
        try teamB.assign(makeHero(id: "3"), at: 1)

        XCTAssertThrowsError(try useCase.execute(teamA: teamA, teamB: teamB)) { error in
            XCTAssertEqual(error as? BattleParticipantsError, .mismatchedDrafts)
        }
    }

    private func makeHero(id: String) -> Hero {
        Hero(id: id, name: "Hero \(id)")
    }
}

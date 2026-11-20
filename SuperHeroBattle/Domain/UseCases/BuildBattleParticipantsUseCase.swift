import Foundation

/// Errors thrown while preparing combat participants.
nonisolated enum BattleParticipantsError: Error, Equatable, Sendable {
    case incompleteTeam(TeamSide)
    case mismatchedDrafts
}

/// Turns two completed drafts into the combat participants.
///
/// It makes no combat decisions: it only validates that both teams are
/// complete and preserves the slot order exactly as the user built it.
nonisolated struct BuildBattleParticipantsUseCase: Sendable {
    init() {}

    func execute(teamA: TeamDraft, teamB: TeamDraft) throws -> BattleParticipants {
        guard teamA.side == .teamA,
              teamB.side == .teamB,
              teamA.mode == teamB.mode else {
            throw BattleParticipantsError.mismatchedDrafts
        }

        guard teamA.isComplete else {
            throw BattleParticipantsError.incompleteTeam(.teamA)
        }

        guard teamB.isComplete else {
            throw BattleParticipantsError.incompleteTeam(.teamB)
        }

        return BattleParticipants(mode: teamA.mode, teamA: teamA.heroes, teamB: teamB.heroes)
    }
}

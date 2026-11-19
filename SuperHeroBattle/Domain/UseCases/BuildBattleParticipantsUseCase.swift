import Foundation

/// Errores al preparar los participantes de un combate.
nonisolated enum BattleParticipantsError: Error, Equatable, Sendable {
    case incompleteTeam(TeamSide)
    case mismatchedDrafts
}

/// Convierte dos borradores completos en los participantes del combate.
///
/// No decide nada del combate: solo valida que ambos equipos estén completos
/// y conserva el orden de los huecos tal y como los formó el usuario.
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

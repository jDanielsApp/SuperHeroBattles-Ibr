import Foundation

nonisolated struct BattleParticipants: Equatable, Sendable {
    let mode: CombatMode
    let teamA: [Hero]
    let teamB: [Hero]
}

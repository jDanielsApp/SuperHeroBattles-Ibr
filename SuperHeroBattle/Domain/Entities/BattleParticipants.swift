import Foundation

nonisolated struct BattleParticipants: Hashable, Sendable {
    let mode: CombatMode
    let teamA: [Hero]
    let teamB: [Hero]
}

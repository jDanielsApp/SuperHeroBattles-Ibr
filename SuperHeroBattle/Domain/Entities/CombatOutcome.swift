import Foundation

nonisolated enum CombatOutcome: Equatable, Hashable, Sendable {
    case winner(TeamSide)
    case draw
}

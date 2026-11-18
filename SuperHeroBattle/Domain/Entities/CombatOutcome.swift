import Foundation

nonisolated enum CombatOutcome: Equatable, Sendable {
    case winner(TeamSide)
    case draw
}

import Foundation

nonisolated struct CombatResult: Equatable, Sendable {
    let mode: CombatMode
    let teamA: TeamCombatSummary
    let teamB: TeamCombatSummary
    let outcome: CombatOutcome
}

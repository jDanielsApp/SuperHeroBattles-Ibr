import Foundation

nonisolated struct TeamCombatSummary: Equatable, Sendable {
    let side: TeamSide
    let combatants: [CombatantScore]
    let affinityBonuses: [AffinityBonus]
    let totalScore: Double
}

import Foundation

/// Immutable history record. It does not keep luck, affinity, or intermediate calculations.
nonisolated struct CombatRecord: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let date: Date
    let mode: CombatMode
    let teamA: [HeroSnapshot]
    let teamB: [HeroSnapshot]
    let outcome: CombatOutcome
    let narration: String
    let narrationSource: NarrativeSource

    init(
        id: UUID = UUID(),
        date: Date,
        mode: CombatMode,
        teamA: [HeroSnapshot],
        teamB: [HeroSnapshot],
        outcome: CombatOutcome,
        narration: String,
        narrationSource: NarrativeSource
    ) {
        self.id = id
        self.date = date
        self.mode = mode
        self.teamA = teamA
        self.teamB = teamB
        self.outcome = outcome
        self.narration = narration
        self.narrationSource = narrationSource
    }
}

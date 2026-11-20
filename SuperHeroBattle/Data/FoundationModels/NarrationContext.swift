import Foundation

/// Deterministic context for a combat narration.
///
/// Built exclusively from the domain and **labels each combatant with
/// their side**: in 2v2 and 3v3, or when the same character appears on both
/// teams, the model needs to tell unambiguously who fights on which side.
/// The `clearWinGap` threshold decides whether the victory is narrated as
/// clear.
nonisolated struct NarrationContext: Equatable, Sendable {
    /// Point gap from which a victory counts as clear.
    static let clearWinGap: Double = 30

    /// A combatant labeled with their side and scores.
    struct HeroContext: Equatable, Sendable {
        let side: TeamSide
        let hero: Hero
        let baseScore: Double
        let luck: Int
        let totalScore: Double
    }

    let mode: CombatMode
    let heroes: [HeroContext]
    let teamABonuses: [AffinityBonus]
    let teamBBonuses: [AffinityBonus]
    let teamATotal: Double
    let teamBTotal: Double
    let outcome: CombatOutcome
    let gap: Double
    let isClearWin: Bool

    init(result: CombatResult, participants: BattleParticipants) {
        mode = result.mode
        outcome = result.outcome
        teamABonuses = result.teamA.affinityBonuses
        teamBBonuses = result.teamB.affinityBonuses
        teamATotal = result.teamA.totalScore
        teamBTotal = result.teamB.totalScore
        gap = abs(teamATotal - teamBTotal)
        isClearWin = gap >= Self.clearWinGap

        let rosterByID = Dictionary(
            (participants.teamA + participants.teamB).map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        var labeled: [HeroContext] = []
        for summary in [result.teamA, result.teamB] {
            let combatants = summary.combatants.map { score in
                HeroContext(
                    side: summary.side,
                    hero: rosterByID[score.hero.id]
                        ?? Hero(id: score.hero.id, name: score.hero.name),
                    baseScore: score.baseScore,
                    luck: score.luck,
                    totalScore: score.totalScore
                )
            }
            labeled.append(contentsOf: combatants)
        }
        heroes = labeled
    }

    func heroes(in side: TeamSide) -> [HeroContext] {
        heroes.filter { $0.side == side }
    }

    func heroName(id: String) -> String? {
        heroes.first { $0.hero.id == id }?.hero.name
    }
}

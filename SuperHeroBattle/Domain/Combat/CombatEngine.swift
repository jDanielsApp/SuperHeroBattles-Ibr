import Foundation

/// Mathematical combat engine.
///
/// Deterministic: the only source of randomness is the injectable
/// `LuckProvider`. Foundation Models never takes part in the calculation.
///
/// Luck consumption order: Team A first, then Team B, in slot order.
/// The same hero on both teams produces two combatants with independent
/// rolls.
nonisolated struct CombatEngine: Sendable {
    private let luckProvider: any LuckProvider

    init(luckProvider: any LuckProvider = SystemLuckProvider()) {
        self.luckProvider = luckProvider
    }

    /// Resolves the full combat and returns a traceable result with
    /// base score, luck, totals, affinity bonus, and winner or draw.
    func resolve(_ participants: BattleParticipants) -> CombatResult {
        let teamA = resolveTeam(.teamA, heroes: participants.teamA)
        let teamB = resolveTeam(.teamB, heroes: participants.teamB)

        return CombatResult(
            mode: participants.mode,
            teamA: teamA,
            teamB: teamB,
            outcome: outcome(teamA: teamA, teamB: teamB)
        )
    }

    private func resolveTeam(_ side: TeamSide, heroes: [Hero]) -> TeamCombatSummary {
        let combatants = heroes.map { hero in
            let base = hero.powerStats.baseScore
            let luck = luckProvider.nextLuck()

            return CombatantScore(
                hero: HeroSnapshot(hero: hero),
                baseScore: base,
                luck: luck,
                totalScore: base + Double(luck)
            )
        }

        let bonuses = feelingBonuses(heroes: heroes)
        let feelingTotal = bonuses.map(\.bonus).reduce(0, +)
        let individualTotal = combatants.map(\.totalScore).reduce(0, +)

        return TeamCombatSummary(
            side: side,
            combatants: combatants,
            affinityBonuses: bonuses,
            totalScore: individualTotal + Double(feelingTotal)
        )
    }

    /// Affinity between teammates of the same team. 1v1 has no pairs,
    /// 2v2 has one, and 3v3 has three. Never compared across teams.
    private func feelingBonuses(heroes: [Hero]) -> [AffinityBonus] {
        var bonuses: [AffinityBonus] = []

        for firstIndex in heroes.indices {
            for secondIndex in heroes.indices where secondIndex > firstIndex {
                if let bonus = AffinityMatcher.bonus(
                    between: heroes[firstIndex],
                    and: heroes[secondIndex]
                ) {
                    bonuses.append(bonus)
                }
            }
        }

        return bonuses
    }

    private func outcome(teamA: TeamCombatSummary, teamB: TeamCombatSummary) -> CombatOutcome {
        if teamA.totalScore > teamB.totalScore {
            return .winner(.teamA)
        }
        if teamB.totalScore > teamA.totalScore {
            return .winner(.teamB)
        }
        return .draw
    }
}

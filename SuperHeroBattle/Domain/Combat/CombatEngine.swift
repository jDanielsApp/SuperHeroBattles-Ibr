import Foundation

/// Motor matemático de combate.
///
/// Determinista: la única fuente de aleatoriedad es el `LuckProvider`
/// inyectable. Foundation Models nunca participa en el cálculo.
///
/// Orden de consumo de la suerte: primero el Equipo A y luego el Equipo B,
/// en el orden de los huecos. El mismo héroe en ambos equipos produce dos
/// combatientes con tiradas independientes.
nonisolated struct CombatEngine: Sendable {
    private let luckProvider: any LuckProvider

    init(luckProvider: any LuckProvider = SystemLuckProvider()) {
        self.luckProvider = luckProvider
    }

    /// Resuelve el combate completo y devuelve un resultado trazable con
    /// base, suerte, totales, feeling y ganador o empate.
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

    /// Feeling entre compañeros del mismo equipo. 1v1 no tiene parejas,
    /// 2v2 tiene una y 3v3 tiene tres. Nunca se compara entre equipos.
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

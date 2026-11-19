import Foundation

/// Narrativa determinista y localizada.
///
/// Se usa como fallback cuando el modelo no está disponible, falla o se
/// agota su tiempo, y directamente en el modo de UI tests con fakes.
/// No simula IA: siempre declara `source: .template`.
nonisolated struct TemplateNarrationService: CombatNarrationService {
    var availability: NarrationAvailability {
        get async { .available }
    }

    func narrate(
        result: CombatResult,
        participants: BattleParticipants,
        language: NarrationLanguage
    ) async throws -> CombatNarrative {
        try Task.checkCancellation()

        let locale = Locale(identifier: language.rawValue)
        let teamAName = L10n.string(.teamSelectionTeamA, locale: locale)
        let teamBName = L10n.string(.teamSelectionTeamB, locale: locale)
        let namesA = result.teamA.combatants.map(\.hero.name).joined(separator: ", ")
        let namesB = result.teamB.combatants.map(\.hero.name).joined(separator: ", ")

        let intro = String(
            format: L10n.string(.combatNarrationTemplateIntro, locale: locale),
            teamAName, namesA, teamBName, namesB
        )

        let scores = String(
            format: L10n.string(.combatNarrationTemplateScores, locale: locale),
            formatted(result.teamA.totalScore, locale: locale),
            formatted(result.teamB.totalScore, locale: locale)
        )

        let outcome: String
        switch result.outcome {
        case .winner(let side):
            outcome = String(
                format: L10n.string(.combatNarrationTemplateWinner, locale: locale),
                side == .teamA ? teamAName : teamBName
            )
        case .draw:
            outcome = L10n.string(.combatNarrationTemplateDraw, locale: locale)
        }

        let text = [intro, scores, outcome].joined(separator: " ")
        return CombatNarrative(text: text, source: .template)
    }

    private func formatted(_ value: Double, locale: Locale) -> String {
        value.formatted(
            .number.precision(.fractionLength(0...1)).locale(locale)
        )
    }
}

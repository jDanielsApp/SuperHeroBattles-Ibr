import Foundation

/// Row text for a combat outcome, in the requested locale.
///
/// Pure and testable: `HistoryView` resolves the locale from the
/// environment so the text always honors the app language, never the
/// system language.
nonisolated enum HistoryOutcomeText {
    static func text(for outcome: CombatOutcome, locale: Locale) -> String {
        switch outcome {
        case .winner(let side):
            let teamName = L10n.string(
                side == .teamA ? .teamSelectionTeamA : .teamSelectionTeamB,
                locale: locale
            )
            return String(format: L10n.string(.historyWinner, locale: locale), teamName)
        case .draw:
            return L10n.string(.combatResultDraw, locale: locale)
        }
    }
}

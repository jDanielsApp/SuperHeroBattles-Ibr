import Foundation

/// Validates the structured narration output before publishing it.
///
/// Rules: all four beats are required; both sides are represented and, when
/// there is a winner, the verdict proclaims it. A side counts as present if
/// its team name appears (English or Spanish, with or without brackets) or
/// any of its heroes does: the model tends to narrate by character name.
/// If the same hero is on both sides, their name satisfies both. If
/// anything fails, it throws `invalidResponse` so the use case honestly
/// falls back to the template.
nonisolated enum NarrationOutputValidator {
    /// Joins the validated beats and returns the final text as paragraphs.
    static func validatedText(
        from narration: GeneratedNarration,
        context: NarrationContext
    ) throws -> String {
        let beats = [
            narration.opening,
            narration.exchange,
            narration.climax,
            narration.verdict,
        ].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard beats.allSatisfy({ !$0.isEmpty }) else {
            throw NarrationError.invalidResponse
        }

        let text = beats.joined(separator: "\n\n")

        guard mentions(.teamA, in: text, context: context) else {
            throw NarrationError.invalidResponse
        }

        guard mentions(.teamB, in: text, context: context) else {
            throw NarrationError.invalidResponse
        }

        if case .winner(let side) = context.outcome {
            guard mentions(side, in: beats[3], context: context) else {
                throw NarrationError.invalidResponse
            }
        }

        return text
    }

    // MARK: - Details

    /// Does the text represent a side? Its team name or any of its
    /// heroes' names counts. Name matching is case-insensitive containment:
    /// we prefer not to over-reject.
    private static func mentions(
        _ side: TeamSide,
        in text: String,
        context: NarrationContext
    ) -> Bool {
        if mentionsTeamName(side, in: text) {
            return true
        }

        let lowered = text.lowercased()
        return context.heroes(in: side).contains { hero in
            lowered.contains(hero.hero.name.lowercased())
        }
    }

    /// Does the text name the team? Accepts English and Spanish.
    private static func mentionsTeamName(_ side: TeamSide, in text: String) -> Bool {
        let lowered = text.lowercased()
        let englishName = side == .teamA ? "team a" : "team b"
        let spanishName = side == .teamA ? "equipo a" : "equipo b"
        return lowered.contains(englishName) || lowered.contains(spanishName)
    }
}

import Foundation

/// Valida la salida estructurada de la narración antes de publicarla.
///
/// Reglas: los cuatro beats obligatorios; el texto debe nombrar a ambos
/// equipos y, si hay ganador, el veredicto debe proclamarlo por el nombre de
/// su equipo. Si algo falla, lanza `invalidResponse` para que el caso de uso
/// caiga honestamente a la plantilla.
nonisolated enum NarrationOutputValidator {
    /// Une los beats validados y devuelve el texto final en párrafos.
    static func validatedText(
        from narration: GeneratedNarration,
        context: NarrationContext,
        language: NarrationLanguage
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

        let locale = Locale(identifier: language.rawValue)
        let teamAName = L10n.string(.teamSelectionTeamA, locale: locale)
        let teamBName = L10n.string(.teamSelectionTeamB, locale: locale)

        guard text.localizedCaseInsensitiveContains(teamAName),
              text.localizedCaseInsensitiveContains(teamBName) else {
            throw NarrationError.invalidResponse
        }

        if case .winner(let side) = context.outcome {
            let winnerName = side == .teamA ? teamAName : teamBName
            guard beats[3].localizedCaseInsensitiveContains(winnerName) else {
                throw NarrationError.invalidResponse
            }
        }

        return text
    }
}

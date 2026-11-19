import Foundation

/// Valida la salida estructurada de la narración antes de publicarla.
///
/// Reglas: los cuatro beats obligatorios; ambos bandos representados y, si
/// hay ganador, el veredicto lo proclama. Un bando cuenta como presente si
/// aparece su nombre de equipo (inglés o español, con o sin corchetes) o
/// cualquiera de sus héroes: el modelo suele narrar por nombres de personaje.
/// Si el mismo héroe está en ambos bandos, su nombre satisface a los dos.
/// Si algo falla, lanza `invalidResponse` para que el caso de uso caiga
/// honestamente a la plantilla.
nonisolated enum NarrationOutputValidator {
    /// Une los beats validados y devuelve el texto final en párrafos.
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

    // MARK: - Detalles

    /// ¿El texto representa a un bando? Vale su nombre de equipo o el nombre
    /// de cualquiera de sus héroes. La coincidencia de nombres es por
    /// contención sin distinguir mayúsculas: preferimos no rechazar de más.
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

    /// ¿El texto nombra al equipo? Acepta inglés y español.
    private static func mentionsTeamName(_ side: TeamSide, in text: String) -> Bool {
        let lowered = text.lowercased()
        let englishName = side == .teamA ? "team a" : "team b"
        let spanishName = side == .teamA ? "equipo a" : "equipo b"
        return lowered.contains(englishName) || lowered.contains(spanishName)
    }
}

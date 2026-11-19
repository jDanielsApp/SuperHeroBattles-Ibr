import Foundation

/// Prompts de narración. Único punto de definición y versionados: cualquier
/// cambio de comportamiento de la IA pasa por aquí y por `version`.
///
/// Contienen exclusivamente datos del dominio (nombres, fichas conocidas y
/// resultado matemático). Nunca tokens, credenciales ni datos personales.
nonisolated enum NarrationPrompts {
    static let version = 1

    /// Instrucciones del sistema: estilo, reglas invariables e idioma.
    static func instructions(language: NarrationLanguage) -> String {
        """
        You are the narrator of a superhero combat simulator with a classic \
        comic-book tone: spectacular, entertaining and vivid.

        Rules you must never break:
        1. The mathematical result provided is final. Never change the winner \
        and never change any score.
        2. Use only the facts provided. Never invent PowerStats or abilities.
        3. Do not translate proper nouns: keep character, team, group and \
        publisher names exactly as provided.
        4. This is a fictional simulation; treat it as such.

        Narrative structure: present both teams, start of the confrontation, \
        standout moments and special attacks, strategies and interactions \
        between characters, resolution, and proclamation of the winner \
        exactly as given.

        Write in \(language.displayName). Plain prose only: no headings, \
        no lists, no quotation marks. Length between 80 and 160 words.

        (prompt version: \(version))
        """
    }

    /// Prompt del combate concreto con los datos inmutables del dominio.
    static func combatPrompt(
        result: CombatResult,
        participants: BattleParticipants,
        language: NarrationLanguage
    ) -> String {
        var lines: [String] = []
        lines.append("Combat mode: \(participants.mode.rawValue).")
        lines.append("Team A:")
        for hero in participants.teamA {
            lines.append("- " + describe(hero))
        }
        lines.append("Team B:")
        for hero in participants.teamB {
            lines.append("- " + describe(hero))
        }
        lines.append(resultLine(result))
        lines.append("Narrate this battle in \(language.displayName).")

        return lines.joined(separator: "\n")
    }

    // MARK: - Detalles

    private static func describe(_ hero: Hero) -> String {
        var parts = [hero.name]

        if let fullName = hero.fullName {
            parts.append("real name: \(fullName)")
        }
        if let publisher = hero.publisher {
            parts.append("publisher: \(publisher)")
        }
        parts.append("alignment: \(hero.alignment.rawValue)")

        let stats = PowerStatKind.allCases.compactMap { kind -> String? in
            guard let value = hero.powerStats[kind] else { return nil }
            return "\(kind.rawValue) \(value)"
        }
        if !stats.isEmpty {
            parts.append("known powerstats: " + stats.joined(separator: ", "))
        }

        let affiliations = AffinityMatcher.normalizedItems(
            from: hero.connections.groupAffiliation
        )
        if !affiliations.isEmpty {
            parts.append("group affiliations: " + affiliations.sorted().joined(separator: ", "))
        }

        let relatives = AffinityMatcher.normalizedItems(
            from: hero.connections.relatives
        )
        if !relatives.isEmpty {
            parts.append("relatives: " + relatives.sorted().joined(separator: ", "))
        }

        return parts.joined(separator: "; ") + "."
    }

    private static func resultLine(_ result: CombatResult) -> String {
        let teamA = formatted(result.teamA.totalScore)
        let teamB = formatted(result.teamB.totalScore)
        let header = "Mathematical result (final, unchangeable): "
            + "Team A scored \(teamA) and Team B scored \(teamB). "

        switch result.outcome {
        case .winner(let side):
            return header + "The winner is \(side == .teamA ? "Team A" : "Team B")."
        case .draw:
            return header + "The combat is a draw."
        }
    }

    private static func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}

nonisolated extension NarrationLanguage {
    /// Nombre del idioma tal y como se pide al modelo.
    var displayName: String {
        switch self {
        case .english: "English"
        case .spanish: "Spanish"
        }
    }
}

import Foundation

/// Prompts de narración. Único punto de definición y versionados: cualquier
/// cambio de comportamiento de la IA pasa por aquí y por `version`.
///
/// Contienen exclusivamente datos del dominio (nombres, fichas conocidas y
/// resultado matemático). Nunca tokens, credenciales ni datos personales.
nonisolated enum NarrationPrompts {
    static let version = 3

    /// Instrucciones del sistema: estilo, reglas invariables e idioma.
    ///
    /// `safeMode` suaviza el vocabulario (acción familiar y no gráfica,
    /// ejemplos neutros) para el reintento tras un rechazo del guardrail.
    static func instructions(language: NarrationLanguage, safeMode: Bool) -> String {
        if safeMode {
            return """
            You are the narrator of a superhero combat simulator with a \
            family-friendly, classic comic-book tone: spectacular, playful \
            and vivid.

            Hard rules you must never break:
            1. The mathematical result provided is final. Never change the \
            winner and never change any score.
            2. Use only the numbers provided. Never invent PowerStats or \
            numeric abilities.
            3. Focus on clever tactics, teamwork and dazzling displays of \
            ability. Never describe injuries, gore or weapons in detail.
            4. Do not translate proper nouns: keep character, team, group \
            and publisher names exactly as provided.
            5. This is a fictional simulation; treat it as such.

            Pace the battle by point difference:
            - CLEAR victory: narrate a decisive, dominant performance with \
            an obvious gap between the sides.
            - CLOSE victory: narrate a hard-fought, evenly matched battle \
            where the winner barely prevails.
            - DRAW: narrate a dead heat with no winner at all.

            Structure the narration in the four provided beats: opening \
            (present both teams by name), exchange (standout moments and \
            dazzling displays of ability), climax (strategies and teamwork \
            that decide the outcome) and verdict (proclaim the winner \
            exactly as given, or the draw). Always mention each hero with \
            the team label given in the roster so both sides stay clearly \
            differentiated.

            Reference style, never copy its content:
            - Batman se funde entre las sombras y supera a su rival con un \
            timing brillante.
            - Joker convierte la arena en una llamativa sala de espejos para \
            desconcertar a sus rivales.

            Write in \(language.displayName). Plain prose only: no headings, \
            no lists, no quotation marks.

            (prompt version: \(version), safe mode)
            """
        }

        return """
        You are the narrator of a superhero combat simulator with a classic \
        comic-book tone: spectacular, entertaining and vivid.

        Hard rules you must never break:
        1. The mathematical result provided is final. Never change the winner \
        and never change any score.
        2. Use only the numbers provided. Never invent PowerStats or numeric \
        abilities.
        3. You may add ONE characteristic flourish per character drawn from \
        that character's well-known fictional lore (signature tools, style, \
        temperament), but never contradict the provided data.
        4. Do not translate proper nouns: keep character, team, group and \
        publisher names exactly as provided.
        5. This is a fictional simulation; treat it as such.

        Pace the battle by point difference:
        - CLEAR victory: narrate a decisive, dominant performance with an \
        obvious gap between the sides.
        - CLOSE victory: narrate a hard-fought, evenly matched battle where \
        the winner barely prevails.
        - DRAW: narrate a dead heat with no winner at all.

        Structure the narration in the four provided beats: opening (present \
        both teams by name), exchange (standout moments and special attacks), \
        climax (strategies and interactions that decide the fight) and \
        verdict (proclaim the winner exactly as given, or the draw). Always \
        mention each hero with the team label given in the roster so both \
        sides stay clearly differentiated.

        Reference style, never copy its content:
        - \(styleExamples(language: language)[0])
        - \(styleExamples(language: language)[1])

        Write in \(language.displayName). Plain prose only: no headings, \
        no lists, no quotation marks.

        (prompt version: \(version))
        """
    }

    /// Prompt del combate concreto a partir del contexto etiquetado.
    static func combatPrompt(
        context: NarrationContext,
        language: NarrationLanguage
    ) -> String {
        var lines: [String] = []
        lines.append("Combat mode: \(context.mode.rawValue).")
        lines.append("Team A: \(rosterSummary(context, side: .teamA)).")
        lines.append("Team B: \(rosterSummary(context, side: .teamB)).")
        lines.append("")
        lines.append("Roster:")
        for hero in context.heroes {
            lines.append("- [\(teamLabel(hero.side))] " + describe(hero))
        }

        let bonuses = affinityLines(context)
        if !bonuses.isEmpty {
            lines.append("")
            lines.append("Affinity bonuses (feeling):")
            lines.append(contentsOf: bonuses)
        }

        lines.append("")
        lines.append(contentsOf: resultLines(context))
        lines.append("Narrate this battle in \(language.displayName).")

        return lines.joined(separator: "\n")
    }

    // MARK: - Detalles

    private static func rosterSummary(_ context: NarrationContext, side: TeamSide) -> String {
        context.heroes(in: side).map(\.hero.name).joined(separator: ", ")
    }

    private static func teamLabel(_ side: TeamSide) -> String {
        side == .teamA ? "TEAM A" : "TEAM B"
    }

    private static func describe(_ hero: NarrationContext.HeroContext) -> String {
        var parts = [hero.hero.name]

        if let fullName = hero.hero.fullName {
            parts.append("real name: \(fullName)")
        }
        if let publisher = hero.hero.publisher {
            parts.append("publisher: \(publisher)")
        }
        parts.append("alignment: \(hero.hero.alignment.rawValue)")

        let stats = PowerStatKind.allCases.compactMap { kind -> String? in
            guard let value = hero.hero.powerStats[kind] else { return nil }
            return "\(kind.rawValue) \(value)"
        }
        if !stats.isEmpty {
            parts.append("known powerstats: " + stats.joined(separator: ", "))
        }

        let affiliations = AffinityMatcher.normalizedItems(
            from: hero.hero.connections.groupAffiliation
        )
        if !affiliations.isEmpty {
            parts.append("group affiliations: " + affiliations.sorted().joined(separator: ", "))
        }

        let relatives = AffinityMatcher.normalizedItems(
            from: hero.hero.connections.relatives
        )
        if !relatives.isEmpty {
            parts.append("relatives: " + relatives.sorted().joined(separator: ", "))
        }

        parts.append(
            "computed base \(formatted(hero.baseScore)), luck \(hero.luck), "
                + "individual total \(formatted(hero.totalScore))"
        )

        return parts.joined(separator: "; ") + "."
    }

    private static func affinityLines(_ context: NarrationContext) -> [String] {
        let bonusesBySide: [(side: TeamSide, bonuses: [AffinityBonus])] = [
            (.teamA, context.teamABonuses),
            (.teamB, context.teamBBonuses),
        ]

        var lines: [String] = []

        for entry in bonusesBySide {
            for bonus in entry.bonuses {
                let firstName = context.heroName(id: bonus.heroAID) ?? bonus.heroAID
                let secondName = context.heroName(id: bonus.heroBID) ?? bonus.heroBID
                let matches = (bonus.matchedAffiliations + bonus.matchedRelatives)
                    .joined(separator: " / ")

                lines.append(
                    "- [\(teamLabel(entry.side))] \(firstName) + \(secondName): "
                        + "+\(bonus.bonus) (\(matches))"
                )
            }
        }

        return lines
    }

    private static func resultLines(_ context: NarrationContext) -> [String] {
        var lines: [String] = []
        lines.append("Mathematical result (final, unchangeable):")

        switch context.outcome {
        case .winner(let side):
            let pace = context.isClearWin ? "CLEAR" : "CLOSE"
            lines.append(
                "- Team A scored \(formatted(context.teamATotal)) and "
                    + "Team B scored \(formatted(context.teamBTotal))."
            )
            lines.append(
                "- Point difference: \(formatted(context.gap)) — the victory is \(pace)."
            )
            lines.append(
                "- The winner is \(side == .teamA ? "Team A" : "Team B")."
            )
        case .draw:
            lines.append(
                "- Team A scored \(formatted(context.teamATotal)) and "
                    + "Team B scored \(formatted(context.teamBTotal))."
            )
            lines.append("- Point difference: 0 — the combat is a DRAW with no winner.")
        }

        return lines
    }

    private static func styleExamples(language: NarrationLanguage) -> [String] {
        switch language {
        case .english:
            [
                "Batman uses the darkness to hurl a batarang soaked in chemical compounds.",
                "Joker anticipates his rival's move and triggers a smoke bomb that reshapes the battlefield."
            ]
        case .spanish:
            [
                "Batman aprovecha la oscuridad para lanzar un batarang impregnado de compuestos químicos.",
                "Joker anticipa el movimiento de su rival y activa una bomba de humo que transforma el campo de batalla."
            ]
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

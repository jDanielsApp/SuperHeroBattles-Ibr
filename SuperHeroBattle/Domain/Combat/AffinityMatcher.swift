import Foundation

/// Cálculo del feeling entre dos compañeros de equipo.
///
/// Reglas de la especificación:
/// - Se comparan `group-affiliation` y `relatives` como listas de elementos
///   individuales separados por comas o puntos y coma.
/// - El contenido entre paréntesis o corchetes se descarta antes de comparar
///   (la API lo usa para roles y notas: "Avengers (honorary member)").
/// - Afiliaciones: coincidencia exacta entre las dos listas normalizadas.
/// - Familiares: el nombre de un familiar debe coincidir con el nombre o un
///   alias de su compañero, en cualquiera de las dos direcciones. Compartir
///   el mismo familiar entre los dos héroes ya no otorga bonus.
/// - La comparación es exacta, sin distinguir mayúsculas y sin espacios sobrantes.
/// - Una coincidencia en cualquiera de los dos campos (OR) aporta +33.
/// - Coincidir en ambos campos sigue aportando +33, nunca 66.
nonisolated enum AffinityMatcher {
    static let bonusPerPair = 33

    private static let unknownMarkers: Set<String> = ["-", "unknown", "none", "n/a"]
    private static let itemSeparators: Set<Character> = [",", ";"]

    /// Normaliza texto libre de la API: separa por comas y puntos y coma,
    /// elimina el contenido entre paréntesis y corchetes, recorta espacios,
    /// compara en minúsculas y descarta vacíos y marcadores de desconocido.
    static func normalizedItems(from text: String?) -> Set<String> {
        guard let text, !text.isEmpty else { return [] }

        return Set(
            text
                .split(whereSeparator: itemSeparators.contains)
                .map { withoutParentheses(String($0)) }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty && !unknownMarkers.contains($0) }
        )
    }

    /// Bonus de una pareja del mismo equipo. `nil` cuando no hay coincidencias.
    static func bonus(between heroA: Hero, and heroB: Hero) -> AffinityBonus? {
        let matchedAffiliations = normalizedItems(from: heroA.connections.groupAffiliation)
            .intersection(normalizedItems(from: heroB.connections.groupAffiliation))
            .sorted()

        let matchedRelatives = matchedRelatives(between: heroA, and: heroB)

        guard !matchedAffiliations.isEmpty || !matchedRelatives.isEmpty else {
            return nil
        }

        return AffinityBonus(
            heroAID: heroA.id,
            heroBID: heroB.id,
            bonus: bonusPerPair,
            matchedAffiliations: matchedAffiliations,
            matchedRelatives: matchedRelatives
        )
    }

    /// Familiares que coinciden con la identidad del compañero: los
    /// familiares de A contra el nombre o alias de B, y los de B contra los
    /// de A. El resultado se publica normalizado, sin paréntesis.
    private static func matchedRelatives(between heroA: Hero, and heroB: Hero) -> [String] {
        let relativesA = normalizedItems(from: heroA.connections.relatives)
        let relativesB = normalizedItems(from: heroB.connections.relatives)

        var matches = relativesA.intersection(identityNames(of: heroB))
        matches.formUnion(relativesB.intersection(identityNames(of: heroA)))

        return matches.sorted()
    }

    /// Identidad de un héroe para el emparejado de familiares: su nombre y
    /// los alias biográficos, con la misma normalización.
    private static func identityNames(of hero: Hero) -> Set<String> {
        var names = normalizedItems(from: hero.name)

        for alias in hero.biography.aliases {
            names.formUnion(normalizedItems(from: alias))
        }

        return names
    }

    /// Elimina los segmentos entre paréntesis y corchetes, tolerando
    /// desequilibrios: "Loki (adoptive brother)[note 1]" queda en "Loki".
    /// Un ítem que solo aporta paréntesis ("(wife)") queda vacío y se
    /// descarta en la normalización.
    private static func withoutParentheses(_ item: String) -> String {
        var result = ""
        var depth = 0

        for character in item {
            switch character {
            case "(", "[":
                depth += 1
            case ")", "]":
                depth = max(0, depth - 1)
            default:
                guard depth == 0 else { continue }
                result.append(character)
            }
        }

        return result
    }
}

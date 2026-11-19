import Foundation

/// Cálculo del feeling entre dos compañeros de equipo.
///
/// Reglas de la especificación:
/// - Se comparan `group-affiliation` y `relatives` como listas de elementos
///   individuales separados por comas.
/// - La comparación es exacta, sin distinguir mayúsculas y sin espacios sobrantes.
/// - Una coincidencia en cualquiera de los dos campos (OR) aporta +33.
/// - Coincidir en ambos campos sigue aportando +33, nunca 66.
nonisolated enum AffinityMatcher {
    static let bonusPerPair = 33

    private static let unknownMarkers: Set<String> = ["-", "unknown", "none", "n/a"]

    /// Normaliza texto libre de la API: separa por comas, recorta espacios,
    /// compara en minúsculas y descarta vacíos y marcadores de desconocido.
    static func normalizedItems(from text: String?) -> Set<String> {
        guard let text, !text.isEmpty else { return [] }

        return Set(
            text
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty && !unknownMarkers.contains($0) }
        )
    }

    /// Bonus de una pareja del mismo equipo. `nil` cuando no hay coincidencias.
    static func bonus(between heroA: Hero, and heroB: Hero) -> AffinityBonus? {
        let matchedAffiliations = normalizedItems(from: heroA.connections.groupAffiliation)
            .intersection(normalizedItems(from: heroB.connections.groupAffiliation))
            .sorted()

        let matchedRelatives = normalizedItems(from: heroA.connections.relatives)
            .intersection(normalizedItems(from: heroB.connections.relatives))
            .sorted()

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
}

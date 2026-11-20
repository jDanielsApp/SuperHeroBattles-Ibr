import Foundation

/// Calculates the affinity bonus between two teammates.
///
/// Rules:
/// - `group-affiliation` and `relatives` are compared as lists of individual
///   items separated by commas or semicolons.
/// - Content in parentheses or brackets is discarded before comparing
///   (the API uses it for roles and notes: "Avengers (honorary member)").
/// - Affiliations: exact match between the two normalized lists.
/// - Relatives: a relative's name must match the teammate's name or one of
///   their aliases, in either direction. Sharing the same relative between
///   the two heroes no longer grants a bonus.
/// - Comparison is exact, case-insensitive, and ignores stray whitespace.
/// - A match in either field (OR) contributes +33.
/// - Matching both fields still contributes +33, never 66.
nonisolated enum AffinityMatcher {
    static let bonusPerPair = 33

    private static let unknownMarkers: Set<String> = ["-", "unknown", "none", "n/a"]
    private static let itemSeparators: Set<Character> = [",", ";"]

    /// Normalizes free-form API text: splits on commas and semicolons,
    /// removes content in parentheses and brackets, trims whitespace,
    /// lowercases, and discards empty items and unknown markers.
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

    /// Bonus for a pair of teammates. `nil` when there are no matches.
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

    /// Relatives that match the teammate's identity: A's relatives against
    /// B's name or aliases, and B's relatives against A's. The result is
    /// published normalized, without parentheses.
    private static func matchedRelatives(between heroA: Hero, and heroB: Hero) -> [String] {
        let relativesA = normalizedItems(from: heroA.connections.relatives)
        let relativesB = normalizedItems(from: heroB.connections.relatives)

        var matches = relativesA.intersection(identityNames(of: heroB))
        matches.formUnion(relativesB.intersection(identityNames(of: heroA)))

        return matches.sorted()
    }

    /// A hero's identity for relative matching: their name and
    /// biographical aliases, with the same normalization.
    private static func identityNames(of hero: Hero) -> Set<String> {
        var names = normalizedItems(from: hero.name)

        for alias in hero.biography.aliases {
            names.formUnion(normalizedItems(from: alias))
        }

        return names
    }

    /// Removes segments in parentheses and brackets, tolerating
    /// unbalanced delimiters: "Loki (adoptive brother)[note 1]" becomes "Loki".
    /// An item consisting only of parentheses ("(wife)") becomes empty
    /// and is discarded during normalization.
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

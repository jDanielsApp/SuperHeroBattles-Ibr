import Foundation

/// Fuente de aleatoriedad inyectable para sortear IDs de personajes,
/// siguiendo el patrón de `RandomHeroPicker`.
nonisolated protocol RandomIDPicker: Sendable {
    /// Sortea `count` IDs únicos de `ids`, excluyendo `excludedIDs`.
    /// Devuelve menos si el índice disponible se agota.
    func pickIDs(from ids: [String], excluding excludedIDs: Set<String>, count: Int) -> [String]
}

nonisolated struct SystemRandomIDPicker: RandomIDPicker {
    init() {}

    func pickIDs(from ids: [String], excluding excludedIDs: Set<String>, count: Int) -> [String] {
        guard count > 0 else { return [] }

        let candidates = ids.filter { !excludedIDs.contains($0) }
        guard !candidates.isEmpty else { return [] }

        if candidates.count <= count {
            return candidates.shuffled()
        }

        return Array(candidates.shuffled().prefix(count))
    }
}

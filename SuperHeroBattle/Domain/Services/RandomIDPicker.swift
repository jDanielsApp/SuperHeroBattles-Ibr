import Foundation

/// Injectable source of randomness for drawing random character IDs,
/// following the pattern of `RandomHeroPicker`.
nonisolated protocol RandomIDPicker: Sendable {
    /// Draws `count` unique IDs from `ids`, excluding `excludedIDs`.
    /// Returns fewer if the available pool runs out.
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

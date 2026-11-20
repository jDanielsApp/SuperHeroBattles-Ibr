import Foundation

/// Draws random IDs from the full character index and fetches their
/// profiles with the local cache in front.
///
/// - Already drawn or excluded IDs are never repeated.
/// - A `notFound` is skipped without breaking the draw.
/// - An empty or exhausted index returns an empty outcome, not an error.
/// - Index or loading errors are propagated so the caller decides
///   how to recover.
nonisolated struct DrawRandomHeroesUseCase: Sendable {
    private let characterIDs: any CharacterIDProviding
    private let loadHeroes: LoadHeroesByIDsUseCase
    private let picker: any RandomIDPicker

    init(
        characterIDs: any CharacterIDProviding,
        loadHeroes: LoadHeroesByIDsUseCase,
        picker: any RandomIDPicker = SystemRandomIDPicker()
    ) {
        self.characterIDs = characterIDs
        self.loadHeroes = loadHeroes
        self.picker = picker
    }

    func execute(
        count: Int,
        excluding excludedIDs: Set<String> = []
    ) async throws -> Outcome {
        guard count > 0 else { return Outcome(heroes: [], drawnIDs: []) }
        try Task.checkCancellation()

        let allIDs = try characterIDs.characterIDs()
        let drawn = picker.pickIDs(from: allIDs, excluding: excludedIDs, count: count)

        guard !drawn.isEmpty else {
            return Outcome(heroes: [], drawnIDs: [])
        }

        try Task.checkCancellation()
        let heroes = try await loadHeroes.execute(ids: drawn)
        try Task.checkCancellation()

        // Drawn IDs are always returned, whether or not they resolve, so
        // the caller never draws the same ones again.
        return Outcome(heroes: heroes, drawnIDs: drawn)
    }

    /// Heroes resolved and IDs drawn in the pick.
    struct Outcome: Sendable {
        let heroes: [Hero]
        let drawnIDs: [String]
    }
}

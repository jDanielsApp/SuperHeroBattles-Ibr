import Foundation

/// Sortea IDs aleatorios del índice completo de personajes y obtiene sus
/// fichas con la caché local delante.
///
/// - Los IDs ya sorteados o excluidos no se repiten.
/// - Un `notFound` se omite sin romper el sorteo.
/// - Índice vacío o agotado devuelve un resultado vacío, no un error.
/// - Los errores del índice o de la carga se propagan para que quien
///   llame decida su respaldo.
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

        // Los IDs sorteados se devuelven siempre, resuelvan o no, para que
        // el llamador no vuelva a sortear los mismos.
        return Outcome(heroes: heroes, drawnIDs: drawn)
    }

    /// Héroes resueltos e IDs sorteados en la tirada.
    struct Outcome: Sendable {
        let heroes: [Hero]
        let drawnIDs: [String]
    }
}

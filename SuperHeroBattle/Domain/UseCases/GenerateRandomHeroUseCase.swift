import Foundation

nonisolated struct GenerateRandomHeroUseCase: Sendable {
    private let catalog: any HeroCatalogRepository
    private let picker: any RandomHeroPicker

    init(catalog: any HeroCatalogRepository, picker: any RandomHeroPicker = SystemRandomHeroPicker()) {
        self.catalog = catalog
        self.picker = picker
    }

    func execute(excluding heroIDs: Set<String>) async throws -> Hero? {
        try Task.checkCancellation()
        let heroes = try await catalog.allHeroes()
        try Task.checkCancellation()
        return picker.pick(from: heroes, excluding: heroIDs)
    }
}

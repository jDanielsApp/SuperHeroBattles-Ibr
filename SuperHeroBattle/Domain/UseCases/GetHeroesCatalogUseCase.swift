import Foundation

nonisolated struct GetHeroesCatalogUseCase: Sendable {
    private let repository: any HeroCatalogRepository

    init(repository: any HeroCatalogRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Hero] {
        try Task.checkCancellation()
        let heroes = try await repository.allHeroes()
        try Task.checkCancellation()
        return heroes
    }
}

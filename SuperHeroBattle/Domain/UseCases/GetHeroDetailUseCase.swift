import Foundation

nonisolated struct GetHeroDetailUseCase: Sendable {
    private let repository: any HeroRepository

    init(repository: any HeroRepository) {
        self.repository = repository
    }

    func execute(id: String) async throws -> Hero {
        try Task.checkCancellation()
        let hero = try await repository.hero(id: id)
        try Task.checkCancellation()
        return hero
    }
}

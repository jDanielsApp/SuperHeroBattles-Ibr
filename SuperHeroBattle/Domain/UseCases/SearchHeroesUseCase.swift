import Foundation

nonisolated struct SearchHeroesUseCase: Sendable {
    private let repository: any HeroRepository

    init(repository: any HeroRepository) {
        self.repository = repository
    }

    func execute(query: String) async throws -> [Hero] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        try Task.checkCancellation()
        let heroes = try await repository.search(query: query)
        try Task.checkCancellation()
        return heroes
    }
}

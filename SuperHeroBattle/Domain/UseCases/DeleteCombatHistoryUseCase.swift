import Foundation

nonisolated struct DeleteCombatHistoryUseCase: Sendable {
    private let repository: any CombatHistoryRepository

    init(repository: any CombatHistoryRepository) {
        self.repository = repository
    }

    func execute(id: UUID) async throws {
        try Task.checkCancellation()
        try await repository.delete(id: id)
    }

    /// Vacia el historial completo.
    func executeAll() async throws {
        try Task.checkCancellation()
        try await repository.deleteAll()
    }
}

import Foundation

nonisolated struct SaveCombatHistoryUseCase: Sendable {
    private let repository: any CombatHistoryRepository

    init(repository: any CombatHistoryRepository) {
        self.repository = repository
    }

    func execute(_ record: CombatRecord) async throws {
        try Task.checkCancellation()
        try await repository.save(record)
    }
}

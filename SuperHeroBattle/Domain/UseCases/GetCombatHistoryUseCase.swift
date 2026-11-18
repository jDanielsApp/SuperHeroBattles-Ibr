import Foundation

nonisolated struct GetCombatHistoryUseCase: Sendable {
    private let repository: any CombatHistoryRepository

    init(repository: any CombatHistoryRepository) {
        self.repository = repository
    }

    func execute() async throws -> [CombatRecord] {
        try Task.checkCancellation()
        let records = try await repository.all()
        try Task.checkCancellation()
        return records
    }
}

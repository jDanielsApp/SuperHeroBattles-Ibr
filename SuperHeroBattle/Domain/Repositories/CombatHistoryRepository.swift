import Foundation

nonisolated protocol CombatHistoryRepository: Sendable {
    func save(_ record: CombatRecord) async throws
    func all() async throws -> [CombatRecord]
    func record(id: UUID) async throws -> CombatRecord?
    func delete(id: UUID) async throws
    func deleteAll() async throws
}

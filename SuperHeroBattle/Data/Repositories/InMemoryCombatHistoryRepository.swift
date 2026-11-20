import Foundation

/// In-memory combat history used as a fallback when Realm is unavailable
/// and as a supporting implementation in tests and UI tests with fakes.
actor InMemoryCombatHistoryRepository: CombatHistoryRepository {
    private var storage: [UUID: CombatRecord] = [:]

    func save(_ record: CombatRecord) async throws {
        try Task.checkCancellation()
        storage[record.id] = record
    }

    func all() async throws -> [CombatRecord] {
        try Task.checkCancellation()
        return storage.values.sorted { $0.date > $1.date }
    }

    func record(id: UUID) async throws -> CombatRecord? {
        try Task.checkCancellation()
        return storage[id]
    }

    func delete(id: UUID) async throws {
        try Task.checkCancellation()
        storage[id] = nil
    }

    func deleteAll() async throws {
        try Task.checkCancellation()
        storage.removeAll()
    }
}

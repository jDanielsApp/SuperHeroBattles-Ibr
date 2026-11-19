import Foundation

/// Historial en memoria usado como respaldo cuando Realm no está disponible
/// y como implementación de apoyo en tests y UI tests con fakes.
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

import Foundation
import RealmSwift

/// Historial de combates persistido en Realm.
///
/// Mismo patrón que `RealmHeroCatalogRepository`: Realm confinado al actor
/// principal, métodos del protocolo `nonisolated` que delegan en helpers
/// aislados y solo entidades de dominio en la interfaz.
@MainActor
final class RealmCombatHistoryRepository: CombatHistoryRepository {
    private let realm: Realm

    init(configuration: Realm.Configuration) throws {
        realm = try Realm(configuration: configuration)
    }

    /// Configuración de producción con el esquema y las migraciones centralizados.
    static func live() throws -> RealmCombatHistoryRepository {
        try RealmCombatHistoryRepository(configuration: RealmStore.configuration())
    }

    nonisolated func save(_ record: CombatRecord) async throws {
        try await saveOnMain(record)
    }

    nonisolated func all() async throws -> [CombatRecord] {
        try await allOnMain()
    }

    nonisolated func record(id: UUID) async throws -> CombatRecord? {
        try await recordOnMain(id: id)
    }

    nonisolated func delete(id: UUID) async throws {
        try await deleteOnMain(id: id)
    }

    nonisolated func deleteAll() async throws {
        try await deleteAllOnMain()
    }

    private func saveOnMain(_ record: CombatRecord) throws {
        try Task.checkCancellation()
        let object = CombatObject(snapshot: CombatRecordSnapshot(record: record))
        try realm.write {
            realm.add(object, update: .modified)
        }
    }

    private func allOnMain() throws -> [CombatRecord] {
        try Task.checkCancellation()
        let objects = realm.objects(CombatObject.self)
            .sorted(byKeyPath: "date", ascending: false)
        return objects.compactMap(Self.makeRecord)
    }

    private func recordOnMain(id: UUID) throws -> CombatRecord? {
        try Task.checkCancellation()
        guard let object = realm.object(ofType: CombatObject.self, forPrimaryKey: id.uuidString) else {
            return nil
        }
        return Self.makeRecord(object)
    }

    private func deleteOnMain(id: UUID) throws {
        try Task.checkCancellation()
        guard let object = realm.object(ofType: CombatObject.self, forPrimaryKey: id.uuidString) else {
            return
        }
        try realm.write {
            realm.delete(object)
        }
    }

    private func deleteAllOnMain() throws {
        try Task.checkCancellation()
        let objects = realm.objects(CombatObject.self)
        try realm.write {
            realm.delete(objects)
        }
    }

    private static func makeRecord(_ object: CombatObject) -> CombatRecord? {
        guard let snapshot = try? JSONDecoder().decode(CombatRecordSnapshot.self, from: object.payload) else {
            return nil
        }
        return snapshot.makeRecord()
    }
}

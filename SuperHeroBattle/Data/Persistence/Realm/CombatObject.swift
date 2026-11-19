import Foundation
import Realm
import RealmSwift

/// Modelo Realm del historial de combates.
///
/// Columnas indexables para ordenar y consultar sin deserializar el payload;
/// el registro completo se conserva como JSON inmutable.
nonisolated final class CombatObject: Object {
    @Persisted(primaryKey: true) var id: String = ""
    @Persisted var date: Date = .distantPast
    @Persisted var mode: String = ""
    @Persisted var payload: Data = Data()

    override init() {
        super.init()
    }

    convenience init(snapshot: CombatRecordSnapshot) {
        self.init()
        id = snapshot.id.uuidString
        date = snapshot.date
        mode = snapshot.mode
        payload = (try? JSONEncoder().encode(snapshot)) ?? Data()
    }
}

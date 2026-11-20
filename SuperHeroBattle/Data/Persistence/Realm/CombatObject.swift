import Foundation
import Realm
import RealmSwift

/// Realm model for the combat history.
///
/// Indexable columns allow sorting and querying without deserializing the payload;
/// the complete record is kept as immutable JSON.
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

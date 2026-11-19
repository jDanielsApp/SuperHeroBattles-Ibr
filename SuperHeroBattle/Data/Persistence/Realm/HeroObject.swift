import Foundation
import Realm
import RealmSwift

/// Modelo Realm del catálogo local.
///
/// Los campos indexables permiten filtrar sin deserializar el payload. El héroe
/// completo se conserva como JSON inmutable para no guardar objetos de dominio.
nonisolated final class HeroObject: Object {
    @Persisted(primaryKey: true) var id: String = ""
    @Persisted var name: String = ""
    @Persisted var publisher: String?
    @Persisted var alignment: String = HeroAlignment.unknown.rawValue
    @Persisted var gender: String?
    @Persisted var payload: Data = Data()
    @Persisted var updatedAt: Date = Date()

    convenience init(record: HeroRecord, updatedAt: Date = Date()) {
        self.init()
        id = record.id
        name = record.name
        publisher = record.publisher
        alignment = record.alignment
        gender = record.gender
        payload = (try? record.encoded()) ?? Data()
        self.updatedAt = updatedAt
    }
}

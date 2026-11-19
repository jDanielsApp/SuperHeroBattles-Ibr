import Foundation
import RealmSwift

/// Punto único de configuración y migraciones de Realm.
nonisolated enum RealmStore {
    /// Versiones de esquema:
    /// - 1: catálogo de héroes (`HeroObject`).
    /// - 2: historial de combates (`CombatObject`). Sin datos que migrar:
    ///       la clase nueva se crea vacía y los modelos previos no cambian.
    static let schemaVersion: UInt64 = 2

    static func configuration(
        inMemory: Bool = false,
        inMemoryIdentifier: String = "SuperHeroBattle.inMemory"
    ) -> Realm.Configuration {
        var configuration = Realm.Configuration(
            schemaVersion: schemaVersion,
            migrationBlock: { _, oldSchemaVersion in
                // v2 solo añade CombatObject; no hay transformaciones de datos.
                if oldSchemaVersion < 2 { /* nada que migrar */ }
            }
        )

        if inMemory {
            configuration.inMemoryIdentifier = inMemoryIdentifier
        }

        return configuration
    }
}

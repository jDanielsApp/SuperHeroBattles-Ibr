import Foundation
import RealmSwift

/// Punto único de configuración y migraciones de Realm.
nonisolated enum RealmStore {
    static let schemaVersion: UInt64 = 1

    static func configuration(
        inMemory: Bool = false,
        inMemoryIdentifier: String = "SuperHeroBattle.inMemory"
    ) -> Realm.Configuration {
        var configuration = Realm.Configuration(
            schemaVersion: schemaVersion,
            migrationBlock: { _, _ in
                // Esquema inicial. Documentar aquí cada migración futura.
            }
        )

        if inMemory {
            configuration.inMemoryIdentifier = inMemoryIdentifier
        }

        return configuration
    }
}

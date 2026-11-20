import Foundation
import RealmSwift

/// Single point of Realm configuration and migration.
nonisolated enum RealmStore {
    /// Schema versions:
    /// - 1: hero catalog (`HeroObject`).
    /// - 2: combat history (`CombatObject`). No data to migrate:
    ///       the new class starts out empty and earlier models are unchanged.
    static let schemaVersion: UInt64 = 2

    static func configuration(
        inMemory: Bool = false,
        inMemoryIdentifier: String = "SuperHeroBattle.inMemory"
    ) -> Realm.Configuration {
        var configuration = Realm.Configuration(
            schemaVersion: schemaVersion,
            migrationBlock: { _, oldSchemaVersion in
                // v2 only adds CombatObject; there are no data transformations.
                if oldSchemaVersion < 2 { /* nothing to migrate */ }
            }
        )

        if inMemory {
            configuration.inMemoryIdentifier = inMemoryIdentifier
        }

        return configuration
    }
}

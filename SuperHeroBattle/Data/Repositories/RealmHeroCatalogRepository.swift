import Foundation
import RealmSwift

/// Catálogo local persistido en Realm.
///
/// Realm queda confinado al actor principal, tal y como exige la arquitectura.
/// Nunca se exponen objetos gestionados: solo se devuelven entidades de dominio.
/// Los métodos del protocolo son `nonisolated` y delegan en helpers aislados.
@MainActor
final class RealmHeroCatalogRepository: HeroCatalogRepository {
    private let realm: Realm

    init(configuration: Realm.Configuration) throws {
        realm = try Realm(configuration: configuration)
    }

    /// Configuración de producción con el esquema y las migraciones centralizados.
    static func live() throws -> RealmHeroCatalogRepository {
        try RealmHeroCatalogRepository(configuration: RealmStore.configuration())
    }

    nonisolated func allHeroes() async throws -> [Hero] {
        try await allHeroesOnMain()
    }

    nonisolated func hero(id: String) async throws -> Hero? {
        try await heroOnMain(id: id)
    }

    nonisolated func heroes(ids: [String]) async throws -> [Hero] {
        try await heroesOnMain(ids: ids)
    }

    nonisolated func upsert(_ heroes: [Hero]) async throws {
        try await upsertOnMain(heroes)
    }

    private func allHeroesOnMain() throws -> [Hero] {
        try Task.checkCancellation()
        let objects = realm.objects(HeroObject.self).sorted(byKeyPath: "name")
        return objects.compactMap(Self.makeHero)
    }

    private func heroOnMain(id: String) throws -> Hero? {
        try Task.checkCancellation()
        guard let object = realm.object(ofType: HeroObject.self, forPrimaryKey: id) else {
            return nil
        }
        return Self.makeHero(object)
    }

    private func heroesOnMain(ids: [String]) throws -> [Hero] {
        guard !ids.isEmpty else { return [] }
        try Task.checkCancellation()

        let objects = realm
            .objects(HeroObject.self)
            .filter(NSPredicate(format: "id IN %@", ids))

        var heroesByID: [String: Hero] = [:]
        for object in objects {
            if let hero = Self.makeHero(object) {
                heroesByID[hero.id] = hero
            }
        }

        return ids.compactMap { heroesByID[$0] }
    }

    private func upsertOnMain(_ heroes: [Hero]) throws {
        guard !heroes.isEmpty else { return }
        try Task.checkCancellation()

        let records = heroes.map { HeroObject(record: HeroRecord(hero: $0)) }
        try realm.write {
            for record in records {
                realm.add(record, update: .modified)
            }
        }
    }

    private static func makeHero(_ object: HeroObject) -> Hero? {
        guard let record = try? HeroRecord.decode(data: object.payload) else {
            return nil
        }
        return record.makeHero()
    }
}

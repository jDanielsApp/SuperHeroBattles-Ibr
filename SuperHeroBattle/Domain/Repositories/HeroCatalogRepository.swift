import Foundation

/// Catálogo local de personajes descargados.
nonisolated protocol HeroCatalogRepository: Sendable {
    func allHeroes() async throws -> [Hero]
    func hero(id: String) async throws -> Hero?
    func heroes(ids: [String]) async throws -> [Hero]
    func upsert(_ heroes: [Hero]) async throws
}

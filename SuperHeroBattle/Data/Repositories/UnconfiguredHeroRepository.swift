import Foundation

/// Repositorio de respaldo cuando falta la configuración de la API.
/// Permite que la app arranque y muestre un error comprensible en la búsqueda.
nonisolated struct UnconfiguredHeroRepository: HeroRepository {
    func search(query: String) async throws -> [Hero] {
        throw HeroRepositoryError.notConfigured
    }

    func hero(id: String) async throws -> Hero {
        throw HeroRepositoryError.notConfigured
    }
}

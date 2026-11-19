import Observation

/// Composición de dependencias de la app. Se irá completando por fases.
@MainActor
@Observable
final class AppContainer {
    let searchHeroes: SearchHeroesUseCase
    let loadHeroesByIDs: LoadHeroesByIDsUseCase
    let characterIDs: any CharacterIDProviding
    let catalogRepository: any HeroCatalogRepository

    init() {
        let remote: any HeroRepository

        if let configuration = SuperHeroAPIConfiguration.live() {
            let client = SuperHeroAPIClient(
                configuration: configuration,
                httpClient: URLSessionHTTPClient()
            )
            let repository = SuperHeroRepository(client: client)
            remote = CachedHeroRepository(
                remote: repository,
                cache: HeroSearchCache()
            )
        } else {
            remote = UnconfiguredHeroRepository()
        }

        let catalog = Self.makeCatalogRepository()

        searchHeroes = SearchHeroesUseCase(repository: remote)
        loadHeroesByIDs = LoadHeroesByIDsUseCase(catalog: catalog, remote: remote)
        characterIDs = BundledCharacterIDProvider()
        catalogRepository = catalog
    }

    func makeCharacterGuideViewModel() -> CharacterGuideViewModel {
        CharacterGuideViewModel(
            characterIDs: characterIDs,
            loadHeroes: loadHeroesByIDs,
            searchHeroes: searchHeroes
        )
    }

    /// Realm es la caché principal. Si no se puede abrir, la app sigue
    /// funcionando con un catálogo en memoria durante esa sesión.
    private static func makeCatalogRepository() -> any HeroCatalogRepository {
        do {
            return try RealmHeroCatalogRepository.live()
        } catch {
            return InMemoryHeroCatalogRepository()
        }
    }
}

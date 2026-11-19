import Observation

/// Composición de dependencias de la app. Se irá completando por fases.
@MainActor
@Observable
final class AppContainer {
    let searchHeroes: SearchHeroesUseCase

    init() {
        let repository: any HeroRepository

        if let configuration = SuperHeroAPIConfiguration.live() {
            let client = SuperHeroAPIClient(
                configuration: configuration,
                httpClient: URLSessionHTTPClient()
            )
            let remote = SuperHeroRepository(client: client)
            repository = CachedHeroRepository(
                remote: remote,
                cache: HeroSearchCache()
            )
        } else {
            repository = UnconfiguredHeroRepository()
        }

        searchHeroes = SearchHeroesUseCase(repository: repository)
    }

    init(searchHeroes: SearchHeroesUseCase) {
        self.searchHeroes = searchHeroes
    }
}

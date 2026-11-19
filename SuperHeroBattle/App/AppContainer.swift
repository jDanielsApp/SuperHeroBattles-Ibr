import Foundation
import Observation

/// Composición de dependencias de la app. Se irá completando por fases.
@MainActor
@Observable
final class AppContainer {
    /// Argumento de lanzamiento que activa los fakes de UI tests.
    static let uiTestFakesArgument = "-uitest-fakes"

    let searchHeroes: SearchHeroesUseCase
    let loadHeroesByIDs: LoadHeroesByIDsUseCase
    let generateRandomHero: GenerateRandomHeroUseCase
    let selectHero: SelectHeroUseCase
    let buildBattleParticipants: BuildBattleParticipantsUseCase
    let resolveCombat: ResolveCombatUseCase
    let characterIDs: any CharacterIDProviding
    let catalogRepository: any HeroCatalogRepository

    init() {
        let usesUITestFakes = ProcessInfo.processInfo.arguments.contains(Self.uiTestFakesArgument)

        let remote: any HeroRepository

        if usesUITestFakes {
            // Modo fakes para UI tests: plantilla sintética, sin red ni token.
            remote = FixedRosterHeroRepository()
        } else if let configuration = SuperHeroAPIConfiguration.live() {
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

        let catalog = usesUITestFakes
            ? InMemoryHeroCatalogRepository(heroes: FixedRosterHeroRepository.roster)
            : Self.makeCatalogRepository()

        searchHeroes = SearchHeroesUseCase(repository: remote)
        loadHeroesByIDs = LoadHeroesByIDsUseCase(catalog: catalog, remote: remote)
        generateRandomHero = GenerateRandomHeroUseCase(catalog: catalog)
        selectHero = SelectHeroUseCase()
        buildBattleParticipants = BuildBattleParticipantsUseCase()
        resolveCombat = ResolveCombatUseCase(
            engine: CombatEngine(luckProvider: SystemLuckProvider())
        )
        characterIDs = usesUITestFakes
            ? FixedCharacterIDProvider(ids: FixedRosterHeroRepository.roster.map(\.id))
            : BundledCharacterIDProvider()
        catalogRepository = catalog
    }

    func makeCharacterGuideViewModel(
        onHeroSelected: HeroSelectionHandler? = nil
    ) -> CharacterGuideViewModel {
        CharacterGuideViewModel(
            characterIDs: characterIDs,
            loadHeroes: loadHeroesByIDs,
            searchHeroes: searchHeroes,
            onHeroSelected: onHeroSelected
        )
    }

    func makeTeamSelectionViewModel(mode: CombatMode) -> TeamSelectionViewModel {
        TeamSelectionViewModel(
            mode: mode,
            selectHero: selectHero,
            generateRandomHero: generateRandomHero,
            buildBattleParticipants: buildBattleParticipants,
            preloadHeroes: loadHeroesByIDs,
            characterIDs: characterIDs
        )
    }

    func makeCombatViewModel(participants: BattleParticipants) -> CombatViewModel {
        CombatViewModel(participants: participants, resolveCombat: resolveCombat)
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

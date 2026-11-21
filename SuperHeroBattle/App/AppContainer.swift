import Foundation
import Observation

/// Composition of the app's dependencies.
@MainActor
@Observable
final class AppContainer {
    /// Launch argument that enables the UI test fakes.
    static let uiTestFakesArgument = "-uitest-fakes"

    let searchHeroes: SearchHeroesUseCase
    let loadHeroesByIDs: LoadHeroesByIDsUseCase
    let generateRandomHero: GenerateRandomHeroUseCase
    let drawRandomHeroes: DrawRandomHeroesUseCase
    let selectHero: SelectHeroUseCase
    let buildBattleParticipants: BuildBattleParticipantsUseCase
    let resolveCombat: ResolveCombatUseCase
    let generateCombatNarration: GenerateCombatNarrationUseCase
    let saveCombatHistory: SaveCombatHistoryUseCase
    let getCombatHistory: GetCombatHistoryUseCase
    let deleteCombatHistory: DeleteCombatHistoryUseCase
    let characterIDs: any CharacterIDProviding
    let catalogRepository: any HeroCatalogRepository
    let historyRepository: any CombatHistoryRepository
    let heroImages: any HeroImageLoading

    init() {
        let usesUITestFakes = ProcessInfo.processInfo.arguments.contains(Self.uiTestFakesArgument)

        let remote: any HeroRepository

        if usesUITestFakes {
            // UI test fake mode: synthetic roster, no network and no token.
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

        // The AI service is only instantiated outside fake mode; the template
        // always remains an honest, deterministic fallback.
        let templateNarration = TemplateNarrationService()
        let narrationService: any CombatNarrationService = usesUITestFakes
            ? templateNarration
            : FoundationModelsNarrationService()
        generateCombatNarration = GenerateCombatNarrationUseCase(
            service: narrationService,
            fallback: templateNarration
        )

        let history = usesUITestFakes
            ? InMemoryCombatHistoryRepository()
            : Self.makeHistoryRepository()
        saveCombatHistory = SaveCombatHistoryUseCase(repository: history)
        getCombatHistory = GetCombatHistoryUseCase(repository: history)
        deleteCombatHistory = DeleteCombatHistoryUseCase(repository: history)
        historyRepository = history

        characterIDs = usesUITestFakes
            ? FixedCharacterIDProvider(ids: FixedRosterHeroRepository.roster.map(\.id))
            : BundledCharacterIDProvider()
        catalogRepository = catalog
        heroImages = HeroImageStore()

        drawRandomHeroes = DrawRandomHeroesUseCase(
            characterIDs: characterIDs,
            loadHeroes: loadHeroesByIDs
        )
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
            drawRandomHeroes: drawRandomHeroes,
            buildBattleParticipants: buildBattleParticipants
        )
    }

    func makeCombatViewModel(
        participants: BattleParticipants,
        language: NarrationLanguage,
        onSaved: (@MainActor () -> Void)? = nil
    ) -> CombatViewModel {
        CombatViewModel(
            participants: participants,
            resolveCombat: resolveCombat,
            generateNarration: generateCombatNarration,
            narrationLanguage: language,
            saveCombatHistory: saveCombatHistory,
            onSaved: onSaved
        )
    }

    func makeCombatHistoryViewModel() -> CombatHistoryViewModel {
        CombatHistoryViewModel(
            getHistory: getCombatHistory,
            deleteHistory: deleteCombatHistory
        )
    }

    func makeCombatRecordDetailViewModel(record: CombatRecord) -> CombatRecordDetailViewModel {
        CombatRecordDetailViewModel(
            record: record,
            deleteHistory: deleteCombatHistory
        )
    }

    /// Realm is the primary store. If it cannot be opened, the app keeps
    /// running with an in-memory catalog for that session.
    private static func makeCatalogRepository() -> any HeroCatalogRepository {
        do {
            return try RealmHeroCatalogRepository.live()
        } catch {
            return InMemoryHeroCatalogRepository()
        }
    }

    /// Same approach for combat history: Realm as the primary store and
    /// memory as the session fallback when it cannot be opened.
    private static func makeHistoryRepository() -> any CombatHistoryRepository {
        do {
            return try RealmCombatHistoryRepository.live()
        } catch {
            return InMemoryCombatHistoryRepository()
        }
    }
}

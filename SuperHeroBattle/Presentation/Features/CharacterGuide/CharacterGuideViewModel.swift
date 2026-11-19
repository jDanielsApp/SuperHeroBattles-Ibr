import Foundation

/// Estado de la Guía: catálogo paginado por IDs y búsqueda explícita.
@MainActor
@Observable
final class CharacterGuideViewModel {
    static let pageSize = 30
    static let prefetchThreshold = 5

    let search: HeroSearchViewModel

    private(set) var isSearching = false
    private(set) var catalogHeroes: [Hero] = []
    private(set) var isLoadingPage = false
    private(set) var hasMorePages = false
    private(set) var catalogFailure: HeroCatalogFailure?
    private(set) var pageFailure: HeroSearchFailure?
    private(set) var totalCharacterCount = 0
    private(set) var publisherOptions: [String] = []
    private(set) var genderOptions: [String] = []

    var filter = HeroFilter()

    private let characterIDs: any CharacterIDProviding
    private let loadHeroes: LoadHeroesByIDsUseCase
    private let filterHeroes: FilterHeroesUseCase

    private var ids: [String] = []
    private var nextIndex = 0
    private var hasLoadedCatalog = false

    @ObservationIgnored private var pageTask: Task<Void, Never>?
    @ObservationIgnored private var pageGeneration = 0

    init(
        characterIDs: any CharacterIDProviding,
        loadHeroes: LoadHeroesByIDsUseCase,
        searchHeroes: SearchHeroesUseCase,
        filterHeroes: FilterHeroesUseCase = FilterHeroesUseCase()
    ) {
        self.characterIDs = characterIDs
        self.loadHeroes = loadHeroes
        self.filterHeroes = filterHeroes
        self.search = HeroSearchViewModel(searchHeroes: searchHeroes)
    }

    var filteredHeroes: [Hero] {
        filterHeroes.execute(heroes: catalogHeroes, filter: filter)
    }

    var hasActiveFilters: Bool {
        filter.publisher != nil || filter.gender != nil
    }

    var isCatalogEmpty: Bool {
        catalogHeroes.isEmpty
    }

    func loadIfNeeded() {
        guard !hasLoadedCatalog else { return }
        hasLoadedCatalog = true

        do {
            ids = try characterIDs.characterIDs()
        } catch CharacterIDProviderError.empty {
            catalogFailure = .empty
            return
        } catch {
            catalogFailure = .unavailable
            return
        }

        totalCharacterCount = ids.count
        hasMorePages = !ids.isEmpty
        loadNextPage()
    }

    /// Reintenta leer el índice cuando falló el recurso empaquetado.
    func retryCatalog() {
        catalogFailure = nil
        hasLoadedCatalog = false
        loadIfNeeded()
    }

    /// Carga la siguiente página si no hay otra en curso ni un error pendiente.
    func loadNextPage() {
        guard pageTask == nil,
              pageFailure == nil,
              nextIndex < ids.count else {
            return
        }

        let endIndex = min(nextIndex + Self.pageSize, ids.count)
        let pageIDs = Array(ids[nextIndex..<endIndex])
        guard !pageIDs.isEmpty else { return }

        isLoadingPage = true
        pageGeneration &+= 1
        let generation = pageGeneration

        pageTask = Task { [weak self] in
            guard let self else { return }

            do {
                let heroes = try await self.loadHeroes.execute(ids: pageIDs)
                try Task.checkCancellation()
                guard self.pageGeneration == generation else { return }
                self.appendPage(heroes, advancingBy: pageIDs.count)
            } catch is CancellationError {
                guard self.pageGeneration == generation else { return }
                self.finishPageLoading()
            } catch let error as HeroRepositoryError {
                guard self.pageGeneration == generation else { return }
                self.pageFailure = HeroSearchFailure(error: error)
                self.finishPageLoading()
            } catch {
                guard self.pageGeneration == generation else { return }
                self.pageFailure = .unexpected
                self.finishPageLoading()
            }
        }
    }

    func retryPage() {
        guard pageFailure != nil else { return }
        pageFailure = nil
        loadNextPage()
    }

    /// Precarga la página siguiente cuando el usuario se acerca al final visible.
    func prefetchIfNeeded(currentHero: Hero) {
        guard hasMorePages, pageFailure == nil, !isLoadingPage else { return }

        let heroes = filteredHeroes
        guard let index = heroes.firstIndex(of: currentHero) else { return }
        guard index >= heroes.count - Self.prefetchThreshold else { return }

        loadNextPage()
    }

    func submitSearch() {
        guard search.canSubmit else {
            clearSearch()
            return
        }

        isSearching = true
        search.submit()
    }

    func retrySearch() {
        isSearching = true
        search.retry()
    }

    func clearSearch() {
        isSearching = false
        search.clear()
    }

    /// Cancela trabajo en curso al salir de la pantalla sin borrar lo publicado.
    func cancelActiveWork() {
        search.cancelActiveSearch()

        pageTask?.cancel()
        pageTask = nil
        pageGeneration &+= 1

        if isLoadingPage {
            isLoadingPage = false
        }
    }

    func selectPublisher(_ publisher: String?) {
        filter.publisher = publisher
    }

    func selectGender(_ gender: String?) {
        filter.gender = gender
    }

    func clearFilters() {
        filter = HeroFilter()
    }

    private func appendPage(_ heroes: [Hero], advancingBy count: Int) {
        let existingIDs = Set(catalogHeroes.map(\.id))
        let newHeroes = heroes.filter { !existingIDs.contains($0.id) }

        if !newHeroes.isEmpty {
            catalogHeroes.append(contentsOf: newHeroes)
        }

        nextIndex += count
        hasMorePages = nextIndex < ids.count
        refreshFilterOptions()
        finishPageLoading()
    }

    private func finishPageLoading() {
        isLoadingPage = false
        pageTask = nil
    }

    private func refreshFilterOptions() {
        publisherOptions = Set(catalogHeroes.compactMap(\.publisher))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        genderOptions = Set(catalogHeroes.compactMap(\.gender))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}

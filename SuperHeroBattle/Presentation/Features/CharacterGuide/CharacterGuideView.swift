import SwiftUI

/// Character guide: a paginated, ID-based catalog with unified search.
///
/// With `onHeroDetailRequested`, rows request the detail instead of
/// pushing it (iPhone Duo inner-screen split); without the closure,
/// they keep the classic push on the navigation stack.
///
/// Composition only: rows live in `CharacterGuideHeroRow`, the catalog
/// list in `CharacterGuideCatalogList`, and the shared full-screen
/// states in the `Comic*` components.
struct CharacterGuideView: View {
    @State private var viewModel: CharacterGuideViewModel

    /// Direct hero selection for the detail pane in regular
    /// width; overrides the detail push when present.
    let onHeroDetailRequested: ((Hero) -> Void)?

    init(
        viewModel: CharacterGuideViewModel,
        onHeroDetailRequested: ((Hero) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onHeroDetailRequested = onHeroDetailRequested
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        @Bindable var search = viewModel.search

        ZStack {
            ComicBackground()

            VStack(spacing: 12) {
                HeroSearchBar(
                    query: $search.query,
                    canSubmit: search.canSubmit,
                    isLoading: search.isLoading,
                    onSubmit: { viewModel.submitSearch() },
                    onClear: { viewModel.clearSearch() }
                )

                if !viewModel.isSearching {
                    filterBar
                }

                content
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .navigationTitle(L10n.localizedKey(.guideTitle))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Hero.self) { hero in
            HeroDetailView(hero: hero)
        }
        .onAppear {
            viewModel.loadIfNeeded()
        }
        .onDisappear {
            viewModel.cancelActiveWork()
        }
    }

    private var filterBar: some View {
        HeroFilterBar(
            publisherOptions: viewModel.publisherOptions,
            genderOptions: viewModel.genderOptions,
            selectedPublisher: viewModel.filter.publisher,
            selectedGender: viewModel.filter.gender,
            hasActiveFilters: viewModel.hasActiveFilters,
            onSelectPublisher: { viewModel.selectPublisher($0) },
            onSelectGender: { viewModel.selectGender($0) },
            onClear: { viewModel.clearFilters() }
        )
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isSearching {
            searchContent
        } else {
            catalogContent
        }
    }

    // MARK: - Search

    @ViewBuilder
    private var searchContent: some View {
        switch viewModel.search.state {
        case .idle:
            ComicStatusView(
                systemImage: "sparkle.magnifyingglass",
                titleKey: .searchIdleTitle,
                messageKey: .searchIdleMessage,
                accent: ComicPalette.blue
            )
        case .loading:
            ComicLoadingView(
                textKey: .searchLoading,
                accessibilityKey: .accessibilitySearchLoading
            )
        case .empty:
            ComicStatusView(
                systemImage: "questionmark.folder",
                titleKey: .searchEmptyTitle,
                messageKey: .searchEmptyMessage,
                accent: ComicPalette.yellow
            )
        case .results(let heroes):
            searchResults(heroes)
        case .failure(let failure):
            ComicErrorView(
                titleKey: failure.titleKey,
                messageKey: failure.messageKey,
                retryIdentifier: "search.retry",
                retry: { viewModel.retrySearch() }
            )
        }
    }

    private func searchResults(_ heroes: [Hero]) -> some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(heroes) { hero in
                    row(hero, prefetch: false)
                }
            }
            .padding(.vertical, 4)
        }
        .scrollDismissesKeyboard(.interactively)
        .accessibilityIdentifier("search.results")
    }

    // MARK: - Catalog

    @ViewBuilder
    private var catalogContent: some View {
        if let failure = viewModel.catalogFailure {
            ComicErrorView(
                titleKey: failure.titleKey,
                messageKey: failure.messageKey,
                retryIdentifier: "guide.catalog.retry",
                retry: failure == .unavailable ? { viewModel.retryCatalog() } : nil
            )
        } else if viewModel.isLoadingPage && viewModel.catalogHeroes.isEmpty {
            skeletonList
        } else if viewModel.catalogHeroes.isEmpty, let failure = viewModel.pageFailure {
            ComicErrorView(
                titleKey: .searchErrorTitle,
                messageKey: failure.messageKey,
                retryIdentifier: "guide.page.retry",
                retry: { viewModel.retryPage() }
            )
        } else {
            CharacterGuideCatalogList(
                viewModel: viewModel,
                onHeroDetailRequested: onHeroDetailRequested
            )
        }
    }

    private var skeletonList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(0..<CharacterGuideViewModel.pageSize, id: \.self) { _ in
                    HeroSkeletonRow()
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityIdentifier("guide.catalog.loading")
    }

    // MARK: - Rows

    private func row(_ hero: Hero, prefetch: Bool) -> some View {
        CharacterGuideHeroRow(
            hero: hero,
            prefetch: prefetch,
            onSelect: selectionClosure(for: hero),
            onDetailRequested: detailClosure(for: hero),
            onPrefetch: { current in
                viewModel.prefetchIfNeeded(currentHero: current)
            }
        )
    }

    private func selectionClosure(for hero: Hero) -> (@MainActor () -> Void)? {
        guard let onSelect = viewModel.onHeroSelected else { return nil }
        return { onSelect(hero) }
    }

    private func detailClosure(for hero: Hero) -> (@MainActor () -> Void)? {
        guard let onHeroDetailRequested else { return nil }
        return { onHeroDetailRequested(hero) }
    }
}

#Preview {
    NavigationStack {
        CharacterGuideView(
            viewModel: CharacterGuideViewModel(
                characterIDs: BundledCharacterIDProvider(fileURL: nil),
                loadHeroes: LoadHeroesByIDsUseCase(
                    catalog: InMemoryHeroCatalogRepository(),
                    remote: UnconfiguredHeroRepository()
                ),
                searchHeroes: SearchHeroesUseCase(repository: UnconfiguredHeroRepository())
            )
        )
    }
    .preferredColorScheme(.dark)
}

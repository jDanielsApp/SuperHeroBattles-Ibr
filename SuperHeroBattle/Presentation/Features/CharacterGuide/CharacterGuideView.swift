import SwiftUI

/// Character guide: a paginated, ID-based catalog with unified search.
///
/// With `onHeroDetailRequested`, rows request the detail instead of
/// pushing it (iPhone Duo inner-screen split); without the closure,
/// they keep the classic push on the navigation stack.
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
            statusView(
                systemImage: "sparkle.magnifyingglass",
                titleKey: .searchIdleTitle,
                messageKey: .searchIdleMessage,
                accent: ComicPalette.blue
            )
        case .loading:
            loadingView(textKey: .searchLoading, accessibilityKey: .accessibilitySearchLoading)
        case .empty:
            statusView(
                systemImage: "questionmark.folder",
                titleKey: .searchEmptyTitle,
                messageKey: .searchEmptyMessage,
                accent: ComicPalette.yellow
            )
        case .results(let heroes):
            resultsView(heroes)
        case .failure(let failure):
            failureView(
                titleKey: failure.titleKey,
                messageKey: failure.messageKey,
                accessibilityIdentifier: "search.retry",
                retry: { viewModel.retrySearch() }
            )
        }
    }

    private func resultsView(_ heroes: [Hero]) -> some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(heroes) { hero in
                    heroRow(hero, prefetch: false)
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
            failureView(
                titleKey: failure.titleKey,
                messageKey: failure.messageKey,
                accessibilityIdentifier: "guide.catalog.retry",
                retry: failure == .unavailable ? { viewModel.retryCatalog() } : nil
            )
        } else if viewModel.isLoadingPage && viewModel.catalogHeroes.isEmpty {
            skeletonList
        } else if viewModel.catalogHeroes.isEmpty, let failure = viewModel.pageFailure {
            failureView(
                titleKey: .searchErrorTitle,
                messageKey: failure.messageKey,
                accessibilityIdentifier: "guide.page.retry",
                retry: { viewModel.retryPage() }
            )
        } else {
            catalogList
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

    private var catalogList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if viewModel.filteredHeroes.isEmpty {
                    filteredEmptyView
                } else {
                    ForEach(viewModel.filteredHeroes) { hero in
                        heroRow(hero, prefetch: true)
                    }
                }

                catalogFooter
            }
            .padding(.vertical, 4)
        }
        .scrollDismissesKeyboard(.interactively)
        .accessibilityIdentifier("guide.catalog")
    }

    private var filteredEmptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 40, weight: .black))
                .foregroundStyle(ComicPalette.yellow)
                .accessibilityHidden(true)

            L10n.text(.guideCatalogEmptyFiltered)
                .font(ComicTypography.body)
                .foregroundStyle(ComicPalette.paper.opacity(0.78))
                .multilineTextAlignment(.center)

            Button {
                viewModel.clearFilters()
            } label: {
                L10n.text(.guideFiltersClear)
                    .font(ComicTypography.headline)
                    .foregroundStyle(ComicPalette.ink)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(ComicPalette.yellow, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("guide.filter.clear.empty")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    @ViewBuilder
    private var catalogFooter: some View {
        if let failure = viewModel.pageFailure {
            VStack(spacing: 10) {
                L10n.text(failure.messageKey)
                    .font(ComicTypography.body)
                    .foregroundStyle(ComicPalette.paper.opacity(0.72))
                    .multilineTextAlignment(.center)

                Button {
                    viewModel.retryPage()
                } label: {
                    L10n.text(.guideCatalogRetry)
                        .font(ComicTypography.headline)
                        .foregroundStyle(ComicPalette.ink)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(ComicPalette.yellow, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("guide.page.retry")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        } else if viewModel.isLoadingPage {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(ComicPalette.yellow)
                L10n.text(.guideCatalogLoading)
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.paper.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.text(.accessibilityCatalogLoading))
        } else if viewModel.hasMorePages {
            ProgressView()
                .tint(ComicPalette.yellow)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .onAppear {
                    viewModel.loadNextPage()
                }
        } else if !viewModel.catalogHeroes.isEmpty {
            L10n.text(.guideCatalogEnd)
                .font(ComicTypography.caption)
                .foregroundStyle(ComicPalette.paper.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
    }

    @ViewBuilder
    private func heroRow(_ hero: Hero, prefetch: Bool) -> some View {
        if let onSelect = viewModel.onHeroSelected {
            // Team picker sheet: the row selects and dismisses.
            Button {
                onSelect(hero)
            } label: {
                HeroResultRow(hero: hero)
            }
            .buttonStyle(.plain)
            .prefetchActions(prefetch, hero: hero, viewModel: viewModel)
        } else if let onHeroDetailRequested {
            // Inner-screen split: the row asks the pane for the detail.
            Button {
                onHeroDetailRequested(hero)
            } label: {
                HeroResultRow(hero: hero)
            }
            .buttonStyle(.plain)
            .prefetchActions(prefetch, hero: hero, viewModel: viewModel)
        } else {
            NavigationLink(value: hero) {
                HeroResultRow(hero: hero)
            }
            .buttonStyle(.plain)
            .prefetchActions(prefetch, hero: hero, viewModel: viewModel)
        }
    }

    // MARK: - Shared states

    private func statusView(
        systemImage: String,
        titleKey: LocalizableStringKey,
        messageKey: LocalizableStringKey,
        accent: Color
    ) -> some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            Image(systemName: systemImage)
                .font(.system(size: 52, weight: .black))
                .foregroundStyle(accent)
                .accessibilityHidden(true)

            L10n.text(titleKey)
                .font(ComicTypography.title)
                .foregroundStyle(ComicPalette.paper)
                .multilineTextAlignment(.center)

            L10n.text(messageKey)
                .font(ComicTypography.body)
                .foregroundStyle(ComicPalette.paper.opacity(0.72))
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }

    private func loadingView(
        textKey: LocalizableStringKey,
        accessibilityKey: LocalizableStringKey
    ) -> some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            ProgressView()
                .controlSize(.large)
                .tint(ComicPalette.yellow)

            L10n.text(textKey)
                .font(ComicTypography.body)
                .foregroundStyle(ComicPalette.paper.opacity(0.78))

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.text(accessibilityKey))
    }

    private func failureView(
        titleKey: LocalizableStringKey,
        messageKey: LocalizableStringKey,
        accessibilityIdentifier: String,
        retry: (() -> Void)?
    ) -> some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 46, weight: .black))
                .foregroundStyle(ComicPalette.red)
                .accessibilityHidden(true)

            L10n.text(titleKey)
                .font(ComicTypography.title)
                .foregroundStyle(ComicPalette.paper)
                .multilineTextAlignment(.center)

            L10n.text(messageKey)
                .font(ComicTypography.body)
                .foregroundStyle(ComicPalette.paper.opacity(0.72))
                .multilineTextAlignment(.center)

            if let retry {
                Button(action: retry) {
                    L10n.text(.searchErrorRetry)
                        .font(ComicTypography.headline)
                        .foregroundStyle(ComicPalette.ink)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(ComicPalette.yellow, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(accessibilityIdentifier)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
    }
}

// MARK: - Shared prefetch

/// Wraps page prefetching so both row variants can reuse it.
private extension View {
    @ViewBuilder
    func prefetchActions(
        _ enabled: Bool,
        hero: Hero,
        viewModel: CharacterGuideViewModel
    ) -> some View {
        onAppear {
            guard enabled else { return }
            viewModel.prefetchIfNeeded(currentHero: hero)
        }
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

import SwiftUI

/// Guía de personajes: catálogo paginado por IDs con búsqueda unificada.
struct CharacterGuideView: View {
    @State private var viewModel: CharacterGuideViewModel

    init(viewModel: CharacterGuideViewModel) {
        _viewModel = State(initialValue: viewModel)
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

    // MARK: - Búsqueda

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
                    heroLink(hero, prefetch: false)
                }
            }
            .padding(.vertical, 4)
        }
        .scrollDismissesKeyboard(.interactively)
        .accessibilityIdentifier("search.results")
    }

    // MARK: - Catálogo

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
                        heroLink(hero, prefetch: true)
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

    private func heroLink(_ hero: Hero, prefetch: Bool) -> some View {
        NavigationLink(value: hero) {
            HeroResultRow(hero: hero)
        }
        .buttonStyle(.plain)
        .onAppear {
            guard prefetch else { return }
            viewModel.prefetchIfNeeded(currentHero: hero)
        }
    }

    // MARK: - Estados compartidos

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

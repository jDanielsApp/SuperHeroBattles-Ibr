import SwiftUI

/// Pantalla de búsqueda de la Guía de personajes.
struct HeroSearchView: View {
    @State private var viewModel: HeroSearchViewModel

    init(searchHeroes: SearchHeroesUseCase) {
        _viewModel = State(initialValue: HeroSearchViewModel(searchHeroes: searchHeroes))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            ComicBackground()

            VStack(spacing: 16) {
                HeroSearchBar(
                    query: $viewModel.query,
                    canSubmit: viewModel.canSubmit,
                    isLoading: viewModel.isLoading,
                    onSubmit: { viewModel.submit() },
                    onClear: { viewModel.clear() }
                )

                content
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .navigationTitle(L10n.localizedKey(.guideTitle))
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.cancelActiveSearch()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            statusView(
                systemImage: "sparkle.magnifyingglass",
                titleKey: .searchIdleTitle,
                messageKey: .searchIdleMessage,
                accent: ComicPalette.blue
            )
        case .loading:
            loadingView
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
            failureView(failure)
        }
    }

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

    private var loadingView: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            ProgressView()
                .controlSize(.large)
                .tint(ComicPalette.yellow)

            L10n.text(.searchLoading)
                .font(ComicTypography.body)
                .foregroundStyle(ComicPalette.paper.opacity(0.78))

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.text(.accessibilitySearchLoading))
    }

    private func failureView(_ failure: HeroSearchFailure) -> some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 46, weight: .black))
                .foregroundStyle(ComicPalette.red)
                .accessibilityHidden(true)

            L10n.text(failure.titleKey)
                .font(ComicTypography.title)
                .foregroundStyle(ComicPalette.paper)
                .multilineTextAlignment(.center)

            L10n.text(failure.messageKey)
                .font(ComicTypography.body)
                .foregroundStyle(ComicPalette.paper.opacity(0.72))
                .multilineTextAlignment(.center)

            Button {
                viewModel.retry()
            } label: {
                L10n.text(.searchErrorRetry)
                    .font(ComicTypography.headline)
                    .foregroundStyle(ComicPalette.ink)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(ComicPalette.yellow, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("search.retry")

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
    }

    private func resultsView(_ heroes: [Hero]) -> some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(heroes) { hero in
                    HeroResultRow(hero: hero)
                }
            }
            .padding(.vertical, 4)
        }
        .scrollDismissesKeyboard(.interactively)
        .accessibilityIdentifier("search.results")
    }
}

#Preview {
    NavigationStack {
        HeroSearchView(
            searchHeroes: SearchHeroesUseCase(repository: UnconfiguredHeroRepository())
        )
    }
    .preferredColorScheme(.dark)
}

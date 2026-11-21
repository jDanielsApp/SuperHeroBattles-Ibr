import SwiftUI

/// Catalog list: rows with prefetch, the adaptive footer (page loading,
/// failure retry or end of catalog) and the filtered-empty state.
///
/// `HeroCatalogFailure`/`HeroSearchFailure` at screen level keep living
/// in `CharacterGuideView`; this list only renders the loaded heroes.
struct CharacterGuideCatalogList: View {
    let viewModel: CharacterGuideViewModel
    /// The Duo inner-screen detail pane request, when present.
    var onHeroDetailRequested: ((Hero) -> Void)?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if viewModel.filteredHeroes.isEmpty {
                    filteredEmptyView
                } else {
                    ForEach(viewModel.filteredHeroes) { hero in
                        heroRow(hero)
                    }
                }

                catalogFooter
            }
            .padding(.vertical, 4)
        }
        .scrollDismissesKeyboard(.interactively)
        .accessibilityIdentifier("guide.catalog")
    }

    private func heroRow(_ hero: Hero) -> some View {
        CharacterGuideHeroRow(
            hero: hero,
            prefetch: true,
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
        guard let request = onHeroDetailRequested else { return nil }
        return { request(hero) }
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
}

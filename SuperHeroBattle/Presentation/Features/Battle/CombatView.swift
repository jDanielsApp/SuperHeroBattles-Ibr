import SwiftUI

/// Combat result screen: traceable scores, affinity and winner.
///
/// The verdict and the real scores stay in suspense until the narration is
/// published: until then the banner keeps the outcome unknown, the totals
/// rotate random numbers and VoiceOver announces the score as pending. When
/// the narration is published the clash banner is removed, the winner is
/// revealed and the scoreboards show the real values. The mathematical
/// result is immutable at all times.
///
/// Composition only: the intro banner, team panels and saving live in
/// their own components under `Presentation/Components`.
struct CombatView: View {
    @State private var viewModel: CombatViewModel

    init(viewModel: CombatViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// iPhone Duo open (or iPad): the narration sits to the right of the rest.
    private var isWideLayout: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        ZStack {
            ComicBackground()

            if #available(iOS 27.1, *), isWideLayout {
                wideLayout
            } else {
                ScrollView {
                    CombatArrangementLayout(
                        leading: { restBlocks },
                        trailing: { narrationSection },
                        footer: { saveSection }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    .animation(revealAnimation, value: viewModel.isNarrationPublished)
                }
            }
        }
        .navigationTitle(L10n.localizedKey(.combatResultTitle))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadNarration()
        }
    }

    // MARK: - Layout

    /// Duo inner screen: `ArrangementView` decides the axis from the
    /// real geometry —rest and narration side by side in horizontal, stacked
    /// in vertical— and each panel scrolls on its own. Never inside a
    /// common ScrollView: the scroll's infinite height breaks its
    /// axis decision.
    @available(iOS 27.1, *)
    private var wideLayout: some View {
        ArrangementView {
            ScrollView {
                VStack(spacing: 18) {
                    restBlocks
                    saveSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .animation(revealAnimation, value: viewModel.isNarrationPublished)
            }
        } secondary: {
            ScrollView {
                narrationSection
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
        }
        .arrangementViewStyle(.split)
    }

    /// Result blocks: suspense header, verdict and teams.
    private var restBlocks: some View {
        VStack(spacing: 18) {
            if !viewModel.isNarrationPublished {
                CombatIntroBanner()
                    .transition(introTransition)
            }

            CombatOutcomeBanner(
                outcome: viewModel.result.outcome,
                isRevealed: viewModel.isNarrationPublished
            )

            teamPanel(viewModel.result.teamA)

            ComicVersusDivider()

            teamPanel(viewModel.result.teamB)
        }
    }

    private func teamPanel(_ summary: TeamCombatSummary) -> some View {
        CombatTeamPanel(
            summary: summary,
            isRevealed: viewModel.isNarrationPublished,
            teamSize: viewModel.result.mode.teamSize
        )
    }

    private var narrationSection: some View {
        CombatNarrationSection(
            narration: viewModel.narration,
            isLoading: viewModel.isGeneratingNarration
        )
    }

    // MARK: - Suspense

    /// Exit transition for the clash banner; no motion under
    /// Reduce Motion.
    private var introTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .scale)
    }

    private var revealAnimation: Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.4)
    }

    // MARK: - History saving

    private var saveSection: some View {
        CombatSaveSection(
            canSave: viewModel.canSave,
            isBusy: viewModel.isSaving,
            onSave: { await viewModel.save() }
        )
    }
}

#Preview {
    NavigationStack {
        CombatView(
            viewModel: CombatViewModel(
                participants: BattleParticipants(
                    mode: .twoVsTwo,
                    teamA: Array(FixedRosterHeroRepository.roster.prefix(2)),
                    teamB: Array(FixedRosterHeroRepository.roster.dropFirst(2).prefix(2))
                ),
                resolveCombat: ResolveCombatUseCase(),
                generateNarration: GenerateCombatNarrationUseCase(
                    service: TemplateNarrationService(),
                    fallback: TemplateNarrationService()
                ),
                narrationLanguage: .spanish,
                saveCombatHistory: SaveCombatHistoryUseCase(
                    repository: InMemoryCombatHistoryRepository()
                )
            )
        )
    }
    .preferredColorScheme(.dark)
}

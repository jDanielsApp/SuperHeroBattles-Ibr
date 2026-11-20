import SwiftUI

/// Combat result screen: traceable scores, affinity and winner.
///
/// The verdict and the real scores stay in suspense until the narration is
/// published: until then the banner keeps the outcome unknown, the totals
/// rotate random numbers and VoiceOver announces the score as pending. When
/// the narration is published the clash banner is removed, the winner is
/// revealed and the scoreboards show the real values. The mathematical
/// result is immutable at all times.
struct CombatView: View {
    @State private var viewModel: CombatViewModel
    @State private var isPresentingSaveConfirmation = false

    init(viewModel: CombatViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    @Environment(\.locale) private var locale
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
                introBanner
                    .transition(introTransition)
            }

            CombatOutcomeBanner(
                outcome: viewModel.result.outcome,
                isRevealed: viewModel.isNarrationPublished
            )

            teamSection(viewModel.result.teamA)

            ComicVersusDivider()

            teamSection(viewModel.result.teamB)
        }
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

    // MARK: - Combat intro

    /// Decorative clash header: a Lottie slot with a comic burst
    /// fallback. Reduce Motion and a missing asset show the fallback.
    private var introBanner: some View {
        HStack(spacing: 18) {
            teamEmblem("A", color: TeamPalette.teamA)
            ComicLottieView(animationName: "combat_intro", loopMode: .loop) {
                comicBurst
            }
            .frame(width: 104, height: 104)

            teamEmblem("B", color: TeamPalette.teamB)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .accessibilityHidden(true)
    }

    /// Fallback comic burst with the central "VS".
    private var comicBurst: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Capsule()
                    .fill(ComicPalette.yellow.opacity(0.85))
                    .frame(width: 120, height: 20)
                    .rotationEffect(.degrees(Double(index) * 45))
            }

            Circle()
                .fill(ComicPalette.yellow)
                .frame(width: 74, height: 74)

            L10n.text(.homeVersus)
                .font(ComicTypography.title)
                .foregroundStyle(ComicPalette.ink)
                .rotationEffect(.degrees(-6))
        }
    }

    private func teamEmblem(_ label: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.22))
                .frame(width: 46, height: 46)

            Circle()
                .stroke(color, lineWidth: 2)
                .frame(width: 46, height: 46)

            Text(label)
                .font(ComicTypography.headline)
                .foregroundStyle(color)
        }
    }

    // MARK: - History saving

    /// Explicit saving: the button enables once the narration is published
    /// and asks for confirmation before recording the combat and returning Home.
    private var saveSection: some View {
        Button {
            isPresentingSaveConfirmation = true
        } label: {
            ComicCTALabel(
                titleKey: .combatSaveAction,
                systemImage: "tray.and.arrow.down.fill",
                isBusy: viewModel.isSaving,
                isEmphasized: viewModel.canSave
            )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSave)
        .accessibilityIdentifier("combat.save")
        .accessibilityHint(L10n.text(.combatSaveHint))
        .alert(
            L10n.localizedKey(.combatSaveConfirmTitle),
            isPresented: $isPresentingSaveConfirmation
        ) {
            Button(L10n.localizedKey(.combatSaveConfirm)) {
                Task {
                    await viewModel.save()
                }
            }
            .accessibilityIdentifier("combat.save.confirm")

            Button(L10n.localizedKey(.commonCancel), role: .cancel) {}
            .accessibilityIdentifier("combat.save.cancel")
        } message: {
            L10n.text(.combatSaveConfirmMessage)
        }
    }

    // MARK: - Team panel

    private func teamSection(_ summary: TeamCombatSummary) -> some View {
        let accent = summary.side == .teamA ? TeamPalette.teamA : TeamPalette.teamB

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(accent)
                    .frame(width: 14, height: 14)
                    .accessibilityHidden(true)

                L10n.text(summary.side == .teamA ? .teamSelectionTeamA : .teamSelectionTeamB)
                    .font(ComicTypography.headline)
                    .foregroundStyle(ComicPalette.paper)
                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: 8)

                SuspenseScoreText(
                    realValue: summary.totalScore,
                    isRevealed: viewModel.isNarrationPublished,
                    range: SuspenseScore.teamRange(forTeamSize: viewModel.result.mode.teamSize),
                    format: scoreFormat
                )
                .font(ComicTypography.headline)
                .foregroundStyle(ComicPalette.yellow)
                .accessibilityIdentifier("combat.total.\(summary.side.rawValue)")
            }
            .accessibilityElement(children: .combine)

            VStack(spacing: 8) {
                ForEach(summary.combatants) { score in
                    combatantRow(score, side: summary.side)
                }
            }

            affinitySection(summary)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(ComicPalette.midnight.opacity(0.86))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accent.opacity(0.45), lineWidth: 2)
        }
    }

    private func combatantRow(_ score: CombatantScore, side: TeamSide) -> some View {
        HStack(spacing: 12) {
            HeroImageView(url: score.hero.imageURL, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(score.hero.name)
                    .font(ComicTypography.headline)
                    .foregroundStyle(ComicPalette.paper)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    statCaption(.combatResultBase, value: score.baseScore.formatted(scoreFormat))
                    statDivider
                    statCaption(.combatResultLuck, value: String(score.luck))
                    statDivider
                    statTotalCaption(score)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ComicPalette.ink.opacity(0.55))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(ComicPalette.paper.opacity(0.12), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(combatantAccessibilityLabel(score))
        .accessibilityIdentifier("combat.combatant.\(side.rawValue)-\(score.hero.id)")
    }

    // MARK: - Affinity

    /// The affinity section only appears when the team has bonuses; a team
    /// without matches (and 1v1, with no pairs) doesn't show it.
    @ViewBuilder
    private func affinitySection(_ summary: TeamCombatSummary) -> some View {
        if !summary.affinityBonuses.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                L10n.text(.combatResultAffinity)
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.paper.opacity(0.55))

                ForEach(summary.affinityBonuses) { bonus in
                    affinityRow(bonus, in: summary)
                }
            }
        }
    }

    private func affinityRow(_ bonus: AffinityBonus, in summary: TeamCombatSummary) -> some View {
        let firstName = summary.combatants.first { $0.hero.id == bonus.heroAID }?.hero.name ?? bonus.heroAID
        let secondName = summary.combatants.first { $0.hero.id == bonus.heroBID }?.hero.name ?? bonus.heroBID

        return VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("\(firstName) + \(secondName)")
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.paper)
                    .lineLimit(1)

                Spacer(minLength: 6)

                Text("+\(bonus.bonus)")
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.yellow)
            }

            if !bonus.matchedAffiliations.isEmpty {
                Text(bonus.matchedAffiliations.joined(separator: ", "))
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.paper.opacity(0.5))
                    .lineLimit(1)
            }

            if !bonus.matchedRelatives.isEmpty {
                Text(bonus.matchedRelatives.joined(separator: ", "))
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.paper.opacity(0.5))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ComicPalette.blue.opacity(0.16))
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Style details

    private var statDivider: some View {
        Text("·")
            .font(ComicTypography.caption)
            .foregroundStyle(ComicPalette.paper.opacity(0.35))
    }

    private func statCaption(_ key: LocalizableStringKey, value: String) -> some View {
        HStack(spacing: 3) {
            L10n.text(key)
                .font(ComicTypography.caption)
                .foregroundStyle(ComicPalette.paper.opacity(0.55))

            Text(value)
                .font(ComicTypography.caption)
                .foregroundStyle(ComicPalette.paper.opacity(0.8))
        }
    }

    /// Combatant total: kept in suspense until the narration is published.
    private func statTotalCaption(_ score: CombatantScore) -> some View {
        HStack(spacing: 3) {
            L10n.text(.combatResultTotal)
                .font(ComicTypography.caption)
                .foregroundStyle(ComicPalette.paper.opacity(0.55))

            SuspenseScoreText(
                realValue: score.totalScore,
                isRevealed: viewModel.isNarrationPublished,
                format: scoreFormat
            )
            .font(ComicTypography.caption)
            .foregroundStyle(ComicPalette.paper.opacity(0.8))
        }
    }

    private var scoreFormat: FloatingPointFormatStyle<Double> {
        .number.precision(.fractionLength(0...1))
    }

    private func combatantAccessibilityLabel(_ score: CombatantScore) -> String {
        let base = L10n.string(.combatResultBase, locale: locale)
        let luck = L10n.string(.combatResultLuck, locale: locale)
        let total = L10n.string(.combatResultTotal, locale: locale)

        // While in suspense the real total is not announced: the scoreboard is
        // pending narration and the visible number is random.
        let totalDescription = viewModel.isNarrationPublished
            ? score.totalScore.formatted(scoreFormat)
            : L10n.string(.combatScorePending, locale: locale)

        return "\(score.hero.name): \(base) \(score.baseScore.formatted(scoreFormat)), "
            + "\(luck) \(score.luck), \(total) \(totalDescription)"
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

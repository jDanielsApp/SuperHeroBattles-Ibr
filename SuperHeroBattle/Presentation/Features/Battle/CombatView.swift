import SwiftUI

/// Pantalla de resultado del combate: puntuaciones trazables, feeling y ganador.
struct CombatView: View {
    @State private var viewModel: CombatViewModel
    @State private var isPresentingSaveConfirmation = false
    @State private var isBannerAppeared = false

    init(viewModel: CombatViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            ComicBackground()

            ScrollView {
                VStack(spacing: 18) {
                    introBanner

                    outcomeBanner

                    teamSection(viewModel.result.teamA)

                    versusDivider

                    teamSection(viewModel.result.teamB)

                    narrationSection

                    saveSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
        }
        .navigationTitle(L10n.localizedKey(.combatResultTitle))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadNarration()
        }
    }

    // MARK: - Inicio del combate

    /// Cabecera decorativa del choque: slot de Lottie con ráfaga comic de
    /// respaldo. Reduce Motion y ausencia de asset muestran el respaldo.
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

    /// Ráfaga comic de respaldo con el "VS" central.
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

    // MARK: - Guardado en el historial

    /// Guardado explícito: el botón se habilita con la narración publicada
    /// y pide confirmación antes de registrar el combate y volver a Home.
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

    // MARK: - Narración

    @ViewBuilder
    private var narrationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            L10n.text(.combatNarrationTitle)
                .font(ComicTypography.headline)
                .foregroundStyle(ComicPalette.yellow)
                .accessibilityAddTraits(.isHeader)

            if let narration = viewModel.narration {
                sourceBadge(narration.source)

                Text(narration.text)
                    .font(ComicTypography.body)
                    .foregroundStyle(ComicPalette.paper.opacity(0.9))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("combat.narration")
            } else if viewModel.isGeneratingNarration {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(ComicPalette.yellow)

                    L10n.text(.combatNarrationLoading)
                        .font(ComicTypography.body)
                        .foregroundStyle(ComicPalette.paper.opacity(0.7))
                }
                .padding(.vertical, 8)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L10n.text(.combatNarrationLoading))
                .accessibilityIdentifier("combat.narration.loading")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(ComicPalette.midnight.opacity(0.86))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(ComicPalette.paper.opacity(0.18), lineWidth: 2)
        }
    }

    @ViewBuilder
    private func sourceBadge(_ source: NarrativeSource) -> some View {
        let key: LocalizableStringKey = source == .foundationModels
            ? .combatNarrationSourceFoundationModels
            : .combatNarrationSourceTemplate
        let accent: Color = source == .foundationModels
            ? ComicPalette.yellow
            : ComicPalette.blue

        L10n.text(key)
            .font(ComicTypography.caption)
            .foregroundStyle(ComicPalette.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(accent, in: Capsule())
            .accessibilityIdentifier("combat.narration.source")
    }

    // MARK: - Resultado global

    @ViewBuilder
    private var outcomeBanner: some View {
        Group {
            switch viewModel.result.outcome {
            case .winner(let side):
                VStack(spacing: 10) {
                    // Slot de Lottie para la presentación del ganador.
                    ComicLottieView(
                        animationName: "combat_winner",
                        fallbackIcon: "trophy.fill",
                        loopMode: .playOnce
                    )
                    .frame(width: 60, height: 60)

                    L10n.text(.combatResultWinner)
                        .font(ComicTypography.caption)
                        .foregroundStyle(ComicPalette.paper.opacity(0.75))

                    L10n.text(side == .teamA ? .teamSelectionTeamA : .teamSelectionTeamB)
                        .font(ComicTypography.title)
                        .foregroundStyle(side == .teamA ? TeamPalette.teamA : TeamPalette.teamB)
                        .accessibilityIdentifier("combat.outcome")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    ComicPalette.midnight.opacity(0.86),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(ComicPalette.yellow, lineWidth: 2)
                }
            case .draw:
                VStack(spacing: 10) {
                    Image(systemName: "equal.circle.fill")
                        .font(.system(size: 44, weight: .black))
                        .foregroundStyle(ComicPalette.paper)
                        .accessibilityHidden(true)

                    L10n.text(.combatResultDraw)
                        .font(ComicTypography.title)
                        .foregroundStyle(ComicPalette.paper)
                        .accessibilityIdentifier("combat.outcome")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    ComicPalette.midnight.opacity(0.86),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(ComicPalette.paper.opacity(0.35), lineWidth: 2)
                }
            }
        }
        // Entrada sutil del banner de resultado; sin movimiento con Reduce Motion.
        .scaleEffect(isBannerAppeared ? 1 : 0.85)
        .opacity(isBannerAppeared ? 1 : 0)
        .onAppear {
            if reduceMotion {
                isBannerAppeared = true
            } else {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                    isBannerAppeared = true
                }
            }
        }
    }

    // MARK: - Panel de equipo

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

                Text(summary.totalScore, format: scoreFormat)
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
                    statCaption(.combatResultTotal, value: score.totalScore.formatted(scoreFormat))
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

    // MARK: - Feeling

    @ViewBuilder
    private func affinitySection(_ summary: TeamCombatSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            L10n.text(.combatResultAffinity)
                .font(ComicTypography.caption)
                .foregroundStyle(ComicPalette.paper.opacity(0.55))

            if summary.affinityBonuses.isEmpty {
                L10n.text(.combatResultAffinityNone)
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.paper.opacity(0.45))
            } else {
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

    // MARK: - Detalles de estilo

    private var versusDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(ComicPalette.paper.opacity(0.25))
                .frame(height: 2)

            L10n.text(.homeVersus)
                .font(ComicTypography.headline)
                .foregroundStyle(ComicPalette.yellow)

            Rectangle()
                .fill(ComicPalette.paper.opacity(0.25))
                .frame(height: 2)
        }
        .accessibilityHidden(true)
    }

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

    private var scoreFormat: FloatingPointFormatStyle<Double> {
        .number.precision(.fractionLength(0...1))
    }

    private func combatantAccessibilityLabel(_ score: CombatantScore) -> String {
        let base = L10n.string(.combatResultBase, locale: locale)
        let luck = L10n.string(.combatResultLuck, locale: locale)
        let total = L10n.string(.combatResultTotal, locale: locale)

        return "\(score.hero.name): \(base) \(score.baseScore.formatted(scoreFormat)), "
            + "\(luck) \(score.luck), \(total) \(score.totalScore.formatted(scoreFormat))"
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

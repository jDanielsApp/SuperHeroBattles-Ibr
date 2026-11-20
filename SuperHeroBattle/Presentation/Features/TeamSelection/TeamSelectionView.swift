import SwiftUI

/// Team selection for the chosen combat mode.
struct TeamSelectionView: View {
    @State private var viewModel: TeamSelectionViewModel
    let container: AppContainer

    @State private var pickerTarget: PickerTarget?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Open iPhone Duo (or iPad): the teams sit side by side.
    private var isWideLayout: Bool {
        horizontalSizeClass == .regular
    }

    init(viewModel: TeamSelectionViewModel, container: AppContainer) {
        _viewModel = State(initialValue: viewModel)
        self.container = container
    }

    /// The slot awaiting manual selection in the Guide sheet.
    private struct PickerTarget: Identifiable {
        let side: TeamSide
        let slot: Int

        var id: String { "\(side.rawValue)-\(slot)" }
    }

    var body: some View {
        ZStack {
            ComicBackground()

            if #available(iOS 27.1, *), isWideLayout {
                wideLayout
            } else {
                compactLayout
            }
        }
        .navigationTitle(L10n.localizedKey(.teamSelectionTitle))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $pickerTarget) { target in
            pickerSheet(target)
        }
        .onAppear {
            viewModel.prepareRandomPool()
        }
        .onDisappear {
            viewModel.cancelActiveWork()
        }
    }

    // MARK: - Layout

    /// Compact (Duo outer screen, iPhone): the current column layout in
    /// a single scroll, with the "VS" divider and the CTA at the end.
    private var compactLayout: some View {
        ScrollView {
            VStack(spacing: 18) {
                modeHeader

                teamPanel(.teamA)

                ComicVersusDivider()

                teamPanel(.teamB)

                startSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
    }

    /// Duo inner screen: `ArrangementView` picks the axis from the real
    /// geometry — teams side by side in horizontal and stacked in
    /// vertical — and each team scrolls within its own panel, with the
    /// CTA fixed below. The arrangement never goes inside a ScrollView:
    /// the scroll's infinite height breaks its axis decision.
    @available(iOS 27.1, *)
    private var wideLayout: some View {
        VStack(spacing: 0) {
            modeHeader
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 12)

            ArrangementView {
                scrollablePanel(.teamA)
            } secondary: {
                scrollablePanel(.teamB)
            }
            .arrangementViewStyle(.split)

            startSection
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 12)
        }
    }

    /// Team panel with its own scroll for its half of the arrangement.
    private func scrollablePanel(_ side: TeamSide) -> some View {
        ScrollView {
            teamPanel(side)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
    }

    // MARK: - Header

    private var modeHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "figure.boxing")
                .foregroundStyle(ComicPalette.yellow)
                .accessibilityHidden(true)

            L10n.text(viewModel.mode.titleKey)
                .font(ComicTypography.headline)
                .foregroundStyle(ComicPalette.paper)

            Spacer(minLength: 0)
        }
    }

    // MARK: - Team panels

    private func teamPanel(_ side: TeamSide) -> some View {
        let accent = side == .teamA ? TeamPalette.teamA : TeamPalette.teamB

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(accent)
                    .frame(width: 14, height: 14)
                    .accessibilityHidden(true)

                L10n.text(side == .teamA ? .teamSelectionTeamA : .teamSelectionTeamB)
                    .font(ComicTypography.headline)
                    .foregroundStyle(ComicPalette.paper)

                Spacer(minLength: 8)

                Text("\(filledCount(side))/\(viewModel.mode.teamSize)")
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.paper.opacity(0.6))
                    .accessibilityHidden(true)
            }

            VStack(spacing: 8) {
                ForEach(0..<viewModel.mode.teamSize, id: \.self) { slot in
                    TeamSlotView(
                        side: side,
                        slot: slot,
                        hero: viewModel.hero(in: slot, side: side),
                        isBusy: viewModel.busySlot == TeamSlotLocation(side: side, slot: slot),
                        onSelect: {
                            pickerTarget = PickerTarget(side: side, slot: slot)
                        },
                        onRandom: {
                            viewModel.fillRandom(side: side, slot: slot)
                        },
                        onClear: {
                            viewModel.clear(side: side, slot: slot)
                        }
                    )
                }
            }
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
        .accessibilityElement(children: .contain)
    }

    private func filledCount(_ side: TeamSide) -> Int {
        (0..<viewModel.mode.teamSize)
            .filter { viewModel.hero(in: $0, side: side) != nil }
            .count
    }

    // MARK: - Combat start

    /// The CTA lives inside the scroll: a fixed footer would leave the
    /// last slots hidden and their actions unreachable.
    @ViewBuilder
    private var startSection: some View {
        VStack(spacing: 10) {
            if let message = viewModel.message {
                L10n.text(message.messageKey)
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.paper.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .accessibilityIdentifier("team.selection.message")
            }

            if let participants = viewModel.battleParticipants {
                NavigationLink(value: AppRoute.combat(participants)) {
                    ComicCTALabel(titleKey: .teamSelectionStart)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("team.selection.start")
            } else {
                Button {} label: {
                    ComicCTALabel(titleKey: .teamSelectionStart, isEmphasized: false)
                }
                .buttonStyle(.plain)
                .disabled(true)
                .accessibilityIdentifier("team.selection.start")
                .accessibilityHint(L10n.text(.teamSelectionStartHint))
            }
        }
        .padding(.top, 6)
    }

    // MARK: - Manual picker

    private func pickerSheet(_ target: PickerTarget) -> some View {
        NavigationStack {
            CharacterGuideView(
                viewModel: container.makeCharacterGuideViewModel { hero in
                    viewModel.assign(hero, to: target.side, slot: target.slot)
                    pickerTarget = nil
                }
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        pickerTarget = nil
                    } label: {
                        L10n.text(.commonCancel)
                    }
                    .accessibilityIdentifier("team.picker.cancel")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TeamSelectionView(
            viewModel: TeamSelectionViewModel(
                mode: .twoVsTwo,
                selectHero: SelectHeroUseCase(),
                generateRandomHero: GenerateRandomHeroUseCase(
                    catalog: InMemoryHeroCatalogRepository(heroes: FixedRosterHeroRepository.roster)
                ),
                drawRandomHeroes: DrawRandomHeroesUseCase(
                    characterIDs: FixedCharacterIDProvider(
                        ids: FixedRosterHeroRepository.roster.map(\.id)
                    ),
                    loadHeroes: LoadHeroesByIDsUseCase(
                        catalog: InMemoryHeroCatalogRepository(),
                        remote: FixedRosterHeroRepository()
                    )
                ),
                buildBattleParticipants: BuildBattleParticipantsUseCase()
            ),
            container: AppContainer()
        )
    }
    .preferredColorScheme(.dark)
}

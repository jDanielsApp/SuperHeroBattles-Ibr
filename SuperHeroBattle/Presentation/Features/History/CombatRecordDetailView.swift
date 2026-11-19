import SwiftUI

/// Detalle de un combate guardado: equipos, resultado y narración persistida.
struct CombatRecordDetailView: View {
    let record: CombatRecord

    var body: some View {
        ZStack {
            ComicBackground()

            ScrollView {
                VStack(spacing: 18) {
                    header
                    teamSection(.teamA, snapshots: record.teamA)
                    versusDivider
                    teamSection(.teamB, snapshots: record.teamB)
                    narrationSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
        }
        .navigationTitle(L10n.localizedKey(.historyDetailTitle))
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("history.detail")
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text(record.date, format: .dateTime.day().month(.abbreviated).year().hour().minute())
                .font(ComicTypography.body)
                .foregroundStyle(ComicPalette.paper.opacity(0.7))

            outcomeBanner
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            ComicPalette.midnight.opacity(0.86),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(ComicPalette.yellow.opacity(0.6), lineWidth: 2)
        }
    }

    @ViewBuilder
    private var outcomeBanner: some View {
        switch record.outcome {
        case .winner(let side):
            VStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(ComicPalette.yellow)
                    .accessibilityHidden(true)

                L10n.text(side == .teamA ? .teamSelectionTeamA : .teamSelectionTeamB)
                    .font(ComicTypography.title)
                    .foregroundStyle(side == .teamA ? TeamPalette.teamA : TeamPalette.teamB)
                    .accessibilityIdentifier("history.detail.outcome")
            }
        case .draw:
            VStack(spacing: 6) {
                Image(systemName: "equal.circle.fill")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(ComicPalette.paper)
                    .accessibilityHidden(true)

                L10n.text(.combatResultDraw)
                    .font(ComicTypography.title)
                    .foregroundStyle(ComicPalette.paper)
                    .accessibilityIdentifier("history.detail.outcome")
            }
        }
    }

    private func teamSection(_ side: TeamSide, snapshots: [HeroSnapshot]) -> some View {
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

                Spacer(minLength: 0)
            }

            VStack(spacing: 8) {
                ForEach(snapshots) { snapshot in
                    HStack(spacing: 12) {
                        HeroImageView(url: snapshot.imageURL, size: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(snapshot.name)
                                .font(ComicTypography.headline)
                                .foregroundStyle(ComicPalette.paper)
                                .lineLimit(1)

                            if let publisher = snapshot.publisher {
                                Text(publisher)
                                    .font(ComicTypography.caption)
                                    .foregroundStyle(accent)
                                    .lineLimit(1)
                            }
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(ComicPalette.ink.opacity(0.55))
                    }
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
    }

    private var narrationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            L10n.text(.combatNarrationTitle)
                .font(ComicTypography.headline)
                .foregroundStyle(ComicPalette.yellow)

            sourceBadge

            Text(record.narration)
                .font(ComicTypography.body)
                .foregroundStyle(ComicPalette.paper.opacity(0.9))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("history.detail.narration")
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

    private var sourceBadge: some View {
        let key: LocalizableStringKey = record.narrationSource == .foundationModels
            ? .combatNarrationSourceFoundationModels
            : .combatNarrationSourceTemplate
        let accent: Color = record.narrationSource == .foundationModels
            ? ComicPalette.yellow
            : ComicPalette.blue

        return L10n.text(key)
            .font(ComicTypography.caption)
            .foregroundStyle(ComicPalette.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(accent, in: Capsule())
    }

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
}

#Preview {
    NavigationStack {
        CombatRecordDetailView(
            record: CombatRecord(
                date: Date(),
                mode: .twoVsTwo,
                teamA: Array(FixedRosterHeroRepository.roster.prefix(2)).map(HeroSnapshot.init(hero:)),
                teamB: Array(FixedRosterHeroRepository.roster.dropFirst(2).prefix(2)).map(HeroSnapshot.init(hero:)),
                outcome: .winner(.teamA),
                narration: "Simulación ficticia: los equipos se enfrentan con todo.",
                narrationSource: .template
            )
        )
    }
    .preferredColorScheme(.dark)
}

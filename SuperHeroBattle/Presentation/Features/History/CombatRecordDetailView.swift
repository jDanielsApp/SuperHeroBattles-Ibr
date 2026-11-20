import SwiftUI

/// Detalle de un combate guardado: equipos, resultado y narración persistida.
struct CombatRecordDetailView: View {
    let record: CombatRecord

    var body: some View {
        ZStack {
            ComicBackground()

            ScrollView {
                VStack(spacing: 18) {
                    dateHeader

                    CombatOutcomeBanner(
                        outcome: record.outcome,
                        isRevealed: true,
                        outcomeIdentifier: "history.detail.outcome"
                    )

                    teamSection(.teamA, snapshots: record.teamA)
                    ComicVersusDivider()
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

    private var dateHeader: some View {
        Text(record.date, format: .dateTime.day().month(.abbreviated).year().hour().minute())
            .font(ComicTypography.body)
            .foregroundStyle(ComicPalette.paper.opacity(0.7))
            .frame(maxWidth: .infinity)
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
        CombatNarrationSection(
            narration: CombatNarrative(
                text: record.narration,
                source: record.narrationSource
            ),
            textIdentifier: "history.detail.narration",
            sourceIdentifier: "history.detail.narration.source"
        )
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

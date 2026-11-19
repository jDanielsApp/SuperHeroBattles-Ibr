import SwiftUI

/// Puente hacia la fase del motor de combate: muestra los equipos confirmados.
struct CombatPlaceholderView: View {
    let participants: BattleParticipants

    var body: some View {
        ZStack {
            ComicBackground()

            ScrollView {
                VStack(spacing: 18) {
                    teamSection(.teamA, heroes: participants.teamA)

                    versusDivider

                    teamSection(.teamB, heroes: participants.teamB)

                    L10n.text(.combatPlaceholderMessage)
                        .font(ComicTypography.body)
                        .foregroundStyle(ComicPalette.paper.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                        .accessibilityIdentifier("combat.placeholder")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(L10n.localizedKey(.combatPlaceholderTitle))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func teamSection(_ side: TeamSide, heroes: [Hero]) -> some View {
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
                ForEach(heroes) { hero in
                    HeroResultRow(hero: hero)
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
        CombatPlaceholderView(
            participants: BattleParticipants(
                mode: .twoVsTwo,
                teamA: Array(FixedRosterHeroRepository.roster.prefix(2)),
                teamB: Array(FixedRosterHeroRepository.roster.dropFirst(2).prefix(2))
            )
        )
    }
    .preferredColorScheme(.dark)
}

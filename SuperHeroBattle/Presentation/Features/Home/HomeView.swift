import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            ComicBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    header
                    actions
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: AppRoute.settings) {
                    Image(systemName: "gearshape.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(ComicPalette.paper)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(L10n.text(.accessibilityHomeSettings))
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(ComicPalette.yellow)
                L10n.text(.homePublishers)
                    .font(ComicTypography.caption)
                    .tracking(1.6)
                    .foregroundStyle(ComicPalette.yellow)
            }
            .accessibilityHidden(true)

            L10n.text(.appName)
                .font(ComicTypography.display)
                .foregroundStyle(ComicPalette.paper)
                .shadow(color: ComicPalette.blue.opacity(0.65), radius: 0, x: 4, y: 4)
                .fixedSize(horizontal: false, vertical: true)

            L10n.text(.homeTagline)
                .font(ComicTypography.body)
                .foregroundStyle(ComicPalette.paper.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actions: some View {
        VStack(spacing: 16) {
            NavigationLink(value: AppRoute.characterGuide) {
                ComicCard(
                    titleKey: .homeGuideTitle,
                    subtitleKey: .homeGuideSubtitle,
                    systemImage: "person.3.fill",
                    accent: ComicPalette.blue,
                    isPrimary: false,
                    accessibilityKey: .accessibilityHomeGuide
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home.guide")

            NavigationLink(value: AppRoute.duelMode) {
                ComicCard(
                    titleKey: .homeDuelsTitle,
                    subtitleKey: .homeDuelsSubtitle,
                    systemImage: "figure.boxing",
                    accent: ComicPalette.red,
                    isPrimary: true,
                    accessibilityKey: .accessibilityHomeDuels
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(ComicPalette.yellow)
                .frame(height: 3)
                .accessibilityHidden(true)

            L10n.text(.homeDataSource)
                .font(ComicTypography.caption)
                .foregroundStyle(ComicPalette.paper.opacity(0.55))
        }
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .preferredColorScheme(.dark)
}

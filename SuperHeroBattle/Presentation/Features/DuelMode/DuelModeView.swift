import SwiftUI

/// Selección de la modalidad de combate: 1 vs 1, 2 vs 2 o 3 vs 3.
struct DuelModeView: View {
    var body: some View {
        ZStack {
            ComicBackground()

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(CombatMode.allCases) { mode in
                        NavigationLink(value: AppRoute.teamSelection(mode)) {
                            ComicCard(
                                titleKey: mode.titleKey,
                                subtitleKey: mode.subtitleKey,
                                systemImage: mode.systemImage,
                                accent: ComicPalette.red,
                                isPrimary: mode == .threeVsThree,
                                accessibilityKey: mode.accessibilityKey,
                                showsVersusBadge: false
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("duels.mode.\(mode.rawValue)")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .comicReadableWidth()
            }
        }
        .navigationTitle(L10n.localizedKey(.duelsTitle))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        DuelModeView()
    }
    .preferredColorScheme(.dark)
}

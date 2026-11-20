import SwiftUI

/// Decorative "VS" divider shared by combat, team selection, and saved
/// battle detail. Purely decorative: never part of the accessibility
/// tree and it may live in the fold zone.
struct ComicVersusDivider: View {
    var body: some View {
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
    ComicVersusDivider()
        .padding(.horizontal, 40)
        .background(ComicPalette.midnight)
        .preferredColorScheme(.dark)
}

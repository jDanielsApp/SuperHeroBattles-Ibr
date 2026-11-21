import SwiftUI

/// Decorative clash header: a Lottie slot with a comic burst fallback.
/// Reduce Motion and a missing asset show the fallback.
struct CombatIntroBanner: View {
    var body: some View {
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
}

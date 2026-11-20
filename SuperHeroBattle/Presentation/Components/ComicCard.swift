import SwiftUI

/// Action card with a comic panel aesthetic.
struct ComicCard: View {
    let titleKey: LocalizableStringKey
    let subtitleKey: LocalizableStringKey
    let systemImage: String
    let accent: Color
    let isPrimary: Bool
    let accessibilityKey: LocalizableStringKey
    /// Corner "VS" badge; independent of the `isPrimary` emphasis.
    var showsVersusBadge = true

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ComicPalette.ink.opacity(0.82))

                Image(systemName: systemImage)
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(accent)
            }
            .frame(width: 72, height: 72)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(ComicPalette.paper.opacity(0.18), lineWidth: 2)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                L10n.text(titleKey)
                    .font(isPrimary ? ComicTypography.title : ComicTypography.headline)
                    .foregroundStyle(ComicPalette.paper)

                L10n.text(subtitleKey)
                    .font(ComicTypography.body)
                    .foregroundStyle(ComicPalette.paper.opacity(0.76))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.headline.weight(.black))
                .foregroundStyle(accent)
                .accessibilityHidden(true)
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.34), ComicPalette.midnight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(ComicPalette.panelBorder, lineWidth: 3)
        }
        .overlay(alignment: .topTrailing) {
            if isPrimary, showsVersusBadge {
                L10n.text(.homeVersus)
                    .font(.caption.weight(.black))
                    .foregroundStyle(ComicPalette.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(ComicPalette.yellow, in: Capsule())
                    .rotationEffect(.degrees(8))
                    .offset(x: 8, y: -10)
                    .accessibilityHidden(true)
            }
        }
        .shadow(color: accent.opacity(0.30), radius: isPrimary ? 18 : 8, x: 0, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.text(accessibilityKey))
        .accessibilityHint(L10n.text(subtitleKey))
        .accessibilityAddTraits(.isButton)
    }
}

import SwiftUI

/// Vista común de estados ilustrativos: grande, centrada y decorativa.
/// Reutilizada por la columna de detalle vacía del split de la Guía.
struct FeaturePlaceholderView: View {
    let titleKey: LocalizableStringKey
    let headlineKey: LocalizableStringKey
    let messageKey: LocalizableStringKey
    let systemImage: String
    let accent: Color
    /// Badge "Próximamente": solo para funciones aún no disponibles.
    var showsComingSoonBadge = true

    var body: some View {
        ZStack {
            ComicBackground()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.18))
                        .frame(width: 132, height: 132)

                    Image(systemName: systemImage)
                        .font(.system(size: 54, weight: .black))
                        .foregroundStyle(accent)
                }
                .accessibilityHidden(true)

                VStack(spacing: 8) {
                    L10n.text(headlineKey)
                        .font(ComicTypography.title)
                        .foregroundStyle(ComicPalette.paper)
                        .multilineTextAlignment(.center)

                    L10n.text(messageKey)
                        .font(ComicTypography.body)
                        .foregroundStyle(ComicPalette.paper.opacity(0.72))
                        .multilineTextAlignment(.center)
                }

                if showsComingSoonBadge {
                    comingSoonBadge
                }
            }
            .padding(28)
        }
        .navigationTitle(LocalizedStringKey(titleKey.rawValue))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var comingSoonBadge: some View {
        L10n.text(.commonComingSoon)
            .font(ComicTypography.caption)
            .foregroundStyle(ComicPalette.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(ComicPalette.yellow, in: Capsule())
    }
}

#Preview {
    NavigationStack {
        FeaturePlaceholderView(
            titleKey: .guideTitle,
            headlineKey: .guideSplitPlaceholderHeadline,
            messageKey: .guideSplitPlaceholderMessage,
            systemImage: "person.crop.circle.badge.viewfinder",
            accent: ComicPalette.blue,
            showsComingSoonBadge: false
        )
    }
    .preferredColorScheme(.dark)
}

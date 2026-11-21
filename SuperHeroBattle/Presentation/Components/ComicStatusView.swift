import SwiftUI

/// Full-width status placeholder: icon, title and message. Used for
/// empty states, idle hints and other full-screen messages.
struct ComicStatusView: View {
    let systemImage: String
    let titleKey: LocalizableStringKey
    let messageKey: LocalizableStringKey
    let accent: Color

    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            Image(systemName: systemImage)
                .font(.system(size: 52, weight: .black))
                .foregroundStyle(accent)
                .accessibilityHidden(true)

            L10n.text(titleKey)
                .font(ComicTypography.title)
                .foregroundStyle(ComicPalette.paper)
                .multilineTextAlignment(.center)

            L10n.text(messageKey)
                .font(ComicTypography.body)
                .foregroundStyle(ComicPalette.paper.opacity(0.72))
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }
}

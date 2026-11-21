import SwiftUI

/// Full-width loading state with an announced accessibility label.
struct ComicLoadingView: View {
    let textKey: LocalizableStringKey
    let accessibilityKey: LocalizableStringKey

    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            ProgressView()
                .controlSize(.large)
                .tint(ComicPalette.yellow)

            L10n.text(textKey)
                .font(ComicTypography.body)
                .foregroundStyle(ComicPalette.paper.opacity(0.78))

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.text(accessibilityKey))
    }
}

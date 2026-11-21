import SwiftUI

/// Full-width error state with an optional retry action.
struct ComicErrorView: View {
    let titleKey: LocalizableStringKey
    let messageKey: LocalizableStringKey
    /// Accessibility identifier of the retry button; used by UI tests.
    let retryIdentifier: String
    let retry: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 46, weight: .black))
                .foregroundStyle(ComicPalette.red)
                .accessibilityHidden(true)

            L10n.text(titleKey)
                .font(ComicTypography.title)
                .foregroundStyle(ComicPalette.paper)
                .multilineTextAlignment(.center)

            L10n.text(messageKey)
                .font(ComicTypography.body)
                .foregroundStyle(ComicPalette.paper.opacity(0.72))
                .multilineTextAlignment(.center)

            if let retry {
                Button(action: retry) {
                    L10n.text(.searchErrorRetry)
                        .font(ComicTypography.headline)
                        .foregroundStyle(ComicPalette.ink)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(ComicPalette.yellow, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(retryIdentifier)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
    }
}

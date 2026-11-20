import SwiftUI

/// Shared label for comic CTAs (yellow capsule).
///
/// Works the same inside a `Button` or a `NavigationLink`; the caller
/// decides the emphasized (enabled) state and whether to show a loading indicator.
struct ComicCTALabel: View {
    let titleKey: LocalizableStringKey
    var systemImage: String?
    var isBusy = false
    var isEmphasized = true

    var body: some View {
        HStack(spacing: 10) {
            if isBusy {
                ProgressView()
                    .tint(ComicPalette.ink)
            } else if let systemImage {
                Image(systemName: systemImage)
            }

            L10n.text(titleKey)
                .font(ComicTypography.headline)
        }
        .foregroundStyle(ComicPalette.ink.opacity(isEmphasized ? 1 : 0.55))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            isEmphasized ? ComicPalette.yellow : ComicPalette.yellow.opacity(0.35),
            in: Capsule()
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview("Estados") {
    VStack(spacing: 14) {
        ComicCTALabel(titleKey: .teamSelectionStart)
        ComicCTALabel(titleKey: .teamSelectionStart, isEmphasized: false)
        ComicCTALabel(
            titleKey: .combatSaveAction,
            systemImage: "tray.and.arrow.down.fill",
            isBusy: true
        )
    }
    .padding(24)
    .background(ComicPalette.ink)
}

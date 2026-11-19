import SwiftUI

/// Etiqueta compartida de los CTA comic (cápsula amarilla).
///
/// Sirve igual dentro de un `Button` que de un `NavigationLink`; el llamador
/// decide el estado enfatizado (habilitado) y si muestra indicador de carga.
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

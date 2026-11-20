import SwiftUI

/// Divisor decorativo "VS" compartido por el combate, la selección de
/// equipos y el detalle de combates guardados.
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
}

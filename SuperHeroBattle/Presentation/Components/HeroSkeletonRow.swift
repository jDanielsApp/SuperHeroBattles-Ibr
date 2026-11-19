import SwiftUI

/// Fila de carga que mantiene la estructura de `HeroResultRow`.
struct HeroSkeletonRow: View {
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ComicPalette.paper.opacity(0.10))
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(ComicPalette.paper.opacity(0.16))
                    .frame(height: 14)
                    .frame(maxWidth: 180)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(ComicPalette.paper.opacity(0.10))
                    .frame(height: 11)
                    .frame(maxWidth: 110)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ComicPalette.midnight.opacity(0.86))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ComicPalette.panelBorder, lineWidth: 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.text(.accessibilityCatalogLoading))
    }
}

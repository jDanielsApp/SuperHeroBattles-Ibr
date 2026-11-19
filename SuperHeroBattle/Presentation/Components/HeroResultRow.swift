import SwiftUI

/// Fila de resultado de búsqueda.
struct HeroResultRow: View {
    let hero: Hero

    var body: some View {
        HStack(spacing: 14) {
            HeroImageView(url: hero.imageURL)

            VStack(alignment: .leading, spacing: 4) {
                Text(hero.name)
                    .font(ComicTypography.headline)
                    .foregroundStyle(ComicPalette.paper)
                    .lineLimit(1)

                publisherText
                    .font(ComicTypography.body)
                    .foregroundStyle(ComicPalette.paper.opacity(0.7))
                    .lineLimit(1)
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
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var publisherText: some View {
        if let publisher = hero.publisher {
            Text(publisher)
        } else {
            L10n.text(.searchPublisherUnknown)
        }
    }
}

import SwiftUI

/// Fondo compartido de la identidad comic book.
///
/// Degradado base con tramas de imprenta (halftone) y dos manchas de color
/// difuminadas para dar profundidad sin saturar.
struct ComicBackground: View {
    var body: some View {
        LinearGradient(
            colors: [ComicPalette.ink, ComicPalette.midnight, ComicPalette.ink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            HalftoneOverlay()
        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(ComicPalette.blue.opacity(0.20))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: 90, y: -80)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(ComicPalette.red.opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: -80, y: 60)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// Tramas de puntos de baja opacidad, dibujadas en un único `Canvas`.
private struct HalftoneOverlay: View {
    private let spacing: CGFloat = 18
    private let dotRadius: CGFloat = 1.5

    var body: some View {
        Canvas { context, size in
            let dotColor = ComicPalette.paper.opacity(0.05)

            var x = spacing / 2
            while x < size.width {
                var y = spacing / 2
                while y < size.height {
                    let rect = CGRect(
                        x: x - dotRadius,
                        y: y - dotRadius,
                        width: dotRadius * 2,
                        height: dotRadius * 2
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(dotColor))
                    y += spacing
                }
                x += spacing
            }
        }
        .allowsHitTesting(false)
    }
}

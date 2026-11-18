import SwiftUI

/// Fondo compartido de la identidad comic book.
struct ComicBackground: View {
    var body: some View {
        LinearGradient(
            colors: [ComicPalette.ink, ComicPalette.midnight, ComicPalette.ink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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

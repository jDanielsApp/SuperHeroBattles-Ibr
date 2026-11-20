import SwiftUI

/// Shared readable width for single-column layouts on wide screens
/// (open iPhone Duo, iPad, Split View): caps content at a maximum width
/// and centers it when there is room to spare. It is a no-op in compact,
/// so it is applied unconditionally — no fixed widths.
struct ComicReadableWidth: ViewModifier {
    var maxWidth: CGFloat = 640

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    /// Caps the column at a readable width and centers it on wide screens.
    func comicReadableWidth(maxWidth: CGFloat = 640) -> some View {
        modifier(ComicReadableWidth(maxWidth: maxWidth))
    }
}

#Preview("Compact y regular") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ComicPalette.midnight.opacity(0.86))
                    .frame(height: 70)
            }
        }
        .padding(20)
        .comicReadableWidth()
    }
    .background(ComicPalette.midnight)
    .preferredColorScheme(.dark)
}

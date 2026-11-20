import SwiftUI

/// Ancho legible compartido para columnas únicas en pantallas anchas
/// (iPhone Duo abierto, iPad, Split View): acota el contenido a un máximo
/// y lo centra cuando sobra espacio. En compact es un no-op, así que se
/// aplica sin condiciones — sin anchos fijos (regla de la skill iphone-duo).
struct ComicReadableWidth: ViewModifier {
    var maxWidth: CGFloat = 640

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    /// Acota la columna a un ancho legible y la centra en pantallas anchas.
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

import SwiftUI

/// Reparto manual de las pantallas de combate por size class: respaldo
/// para compact y para iOS 26, donde `ArrangementView` (iOS 27.1+) no está
/// disponible. En compact apila los bloques en el orden de la columna
/// única; en regular los coloca lado a lado con el `footer` cerrando la
/// columna izquierda.
///
/// - `leading`: banners, equipos y acciones (columna izquierda).
/// - `trailing`: narración (columna derecha).
/// - `footer`: cierre de la pantalla. En compact termina la columna; en
///   regular cierra la columna izquierda bajo los equipos.
struct CombatArrangementLayout<Leading: View, Trailing: View, Footer: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let trailing: () -> Trailing
    @ViewBuilder let footer: () -> Footer

    init(
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) {
        self.leading = leading
        self.trailing = trailing
        self.footer = footer
    }

    var body: some View {
        if horizontalSizeClass == .regular {
            HStack(alignment: .top, spacing: 18) {
                VStack(spacing: 18) {
                    leading()
                    footer()
                }

                trailing()
            }
        } else {
            VStack(spacing: 18) {
                leading()
                trailing()
                footer()
            }
        }
    }
}

#Preview("Compact y regular") {
    Group {
        CombatArrangementLayout(
            leading: {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ComicPalette.blue.opacity(0.3))
                    .frame(height: 220)
            },
            trailing: {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ComicPalette.red.opacity(0.3))
                    .frame(height: 160)
            },
            footer: {
                Capsule().fill(ComicPalette.yellow).frame(height: 44)
            }
        )
        .padding(20)
        .environment(\.horizontalSizeClass, .compact)

        CombatArrangementLayout(
            leading: {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ComicPalette.blue.opacity(0.3))
                    .frame(height: 220)
            },
            trailing: {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ComicPalette.red.opacity(0.3))
                    .frame(height: 160)
            },
            footer: {
                Capsule().fill(ComicPalette.yellow).frame(height: 44)
            }
        )
        .padding(20)
        .environment(\.horizontalSizeClass, .regular)
    }
    .background(ComicPalette.midnight)
    .preferredColorScheme(.dark)
}

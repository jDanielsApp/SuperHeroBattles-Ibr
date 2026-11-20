import SwiftUI

/// Manual arrangement of the combat screens by size class: fallback for
/// compact and for iOS 26, where `ArrangementView` (iOS 27.1+) is not
/// available. In compact it stacks the blocks in single-column order;
/// in regular it places them side by side, with the `footer` closing the
/// left column.
///
/// - `leading`: banners, teams, and actions (left column).
/// - `trailing`: narration (right column).
/// - `footer`: screen footer. In compact it ends the column; in regular
///   it closes the left column below the teams.
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

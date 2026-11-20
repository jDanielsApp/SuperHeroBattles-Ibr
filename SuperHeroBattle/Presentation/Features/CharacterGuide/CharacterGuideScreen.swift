import SwiftUI

/// Guide screen for iPhone Duo: list and detail side by side on the
/// inner screen (the adaptive `HStack` the HIG maps to a
/// *split arrangement*) and a classic detail push in compact, where the
/// Guide is shown as-is with its own navigation destination.
struct CharacterGuideScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var viewModel: CharacterGuideViewModel
    @State private var detailHero: Hero?

    init(container: AppContainer) {
        _viewModel = State(initialValue: container.makeCharacterGuideViewModel())
    }

    /// iPhone Duo open (or iPad): list and detail side by side.
    private var isWideLayout: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        if #available(iOS 27.1, *), isWideLayout {
            // Duo inner screen: `ArrangementView` decides the axis from
            // the real geometry (the Mail-style pattern from the HIG); catalog and detail
            // already have their own scroll. In compact, a classic detail push.
            ArrangementView {
                CharacterGuideView(viewModel: viewModel) { hero in
                    detailHero = hero
                }
            } secondary: {
                detailPane
            }
            .arrangementViewStyle(.split)
        } else {
            // Compact (Duo outer screen, iPhone): classic push.
            CharacterGuideView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var detailPane: some View {
        if let detailHero {
            HeroDetailView(hero: detailHero)
        } else {
            FeaturePlaceholderView(
                titleKey: .guideTitle,
                headlineKey: .guideSplitPlaceholderHeadline,
                messageKey: .guideSplitPlaceholderMessage,
                systemImage: "person.crop.circle.badge.viewfinder",
                accent: ComicPalette.blue,
                showsComingSoonBadge: false
            )
        }
    }
}

#Preview {
    NavigationStack {
        CharacterGuideScreen(container: AppContainer())
    }
    .preferredColorScheme(.dark)
}

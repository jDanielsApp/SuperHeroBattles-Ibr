import SwiftUI

/// Pantalla de Guía para iPhone Duo: lista y ficha lado a lado en la
/// pantalla interior (el `HStack` adaptativo que la HIG mapea a un
/// *split arrangement*) y push clásico de ficha en compact, donde la
/// Guía se muestra tal cual con su propio destino de navegación.
struct CharacterGuideScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var viewModel: CharacterGuideViewModel
    @State private var detailHero: Hero?

    init(container: AppContainer) {
        _viewModel = State(initialValue: container.makeCharacterGuideViewModel())
    }

    /// iPhone Duo abierto (o iPad): lista y ficha lado a lado.
    private var isWideLayout: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        if #available(iOS 27.1, *), isWideLayout {
            // Pantalla interior del Duo: `ArrangementView` decide el eje con
            // la geometría real (patrón Mail de la HIG); catálogo y ficha ya
            // llevan scroll propio. En compact, push clásico de ficha.
            ArrangementView {
                CharacterGuideView(viewModel: viewModel) { hero in
                    detailHero = hero
                }
            } secondary: {
                detailPane
            }
            .arrangementViewStyle(.split)
        } else {
            // Compact (pantalla exterior del Duo, iPhone): push clásico.
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

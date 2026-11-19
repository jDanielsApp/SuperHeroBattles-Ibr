import SwiftUI

struct RootView: View {
    let container: AppContainer

    @AppStorage("app.language") private var languageRawValue = AppLanguage.system.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .system
    }

    /// Idioma de la narración derivado de la preferencia del usuario.
    private var narrationLanguage: NarrationLanguage {
        NarrationLanguage(rawValue: language.narrationCode) ?? .english
    }

    var body: some View {
        NavigationStack {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .characterGuide:
                        CharacterGuideView(
                            viewModel: container.makeCharacterGuideViewModel()
                        )
                    case .duelMode:
                        DuelModeView()
                    case .settings:
                        SettingsView()
                    case let .teamSelection(mode):
                        TeamSelectionView(
                            viewModel: container.makeTeamSelectionViewModel(mode: mode),
                            container: container
                        )
                    case let .combat(participants):
                        CombatView(
                            viewModel: container.makeCombatViewModel(
                                participants: participants,
                                language: narrationLanguage
                            )
                        )
                    }
                }
        }
        .tint(ComicPalette.yellow)
        .environment(\.locale, language.locale ?? .current)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RootView(container: AppContainer())
}

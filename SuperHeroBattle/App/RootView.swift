import SwiftUI

struct RootView: View {
    let container: AppContainer

    @AppStorage("app.language") private var languageRawValue = AppLanguage.system.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .system
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

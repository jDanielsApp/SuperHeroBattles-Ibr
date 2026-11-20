import SwiftUI

struct SettingsView: View {
    @AppStorage("app.language") private var languageRawValue = AppLanguage.system.rawValue

    var body: some View {
        Form {
            Section {
                Picker(selection: $languageRawValue) {
                    L10n.text(.settingsLanguageSystem)
                        .tag(AppLanguage.system.rawValue)
                    L10n.text(.settingsLanguageEnglish)
                        .tag(AppLanguage.english.rawValue)
                    L10n.text(.settingsLanguageSpanish)
                        .tag(AppLanguage.spanish.rawValue)
                } label: {
                    L10n.text(.settingsLanguage)
                }
            } header: {
                L10n.text(.settingsLanguage)
            }

            Section {
                LabeledContent {
                    Text(verbatim: "1.0")
                } label: {
                    L10n.text(.settingsVersion)
                }
            } header: {
                L10n.text(.settingsAbout)
            }
        }
        .navigationTitle(LocalizedStringKey(LocalizableStringKey.settingsTitle.rawValue))
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("settings.root")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .preferredColorScheme(.dark)
}

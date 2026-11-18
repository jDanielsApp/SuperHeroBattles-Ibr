import SwiftUI

struct DuelModeView: View {
    var body: some View {
        FeaturePlaceholderView(
            titleKey: .duelsTitle,
            headlineKey: .duelsPlaceholderTitle,
            messageKey: .duelsPlaceholderMessage,
            systemImage: "figure.boxing",
            accent: ComicPalette.red
        )
    }
}

#Preview {
    NavigationStack {
        DuelModeView()
    }
    .preferredColorScheme(.dark)
}

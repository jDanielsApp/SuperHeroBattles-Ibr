import SwiftUI

struct CharacterGuideView: View {
    var body: some View {
        FeaturePlaceholderView(
            titleKey: .guideTitle,
            headlineKey: .guidePlaceholderTitle,
            messageKey: .guidePlaceholderMessage,
            systemImage: "person.3.sequence.fill",
            accent: ComicPalette.blue
        )
    }
}

#Preview {
    NavigationStack {
        CharacterGuideView()
    }
    .preferredColorScheme(.dark)
}

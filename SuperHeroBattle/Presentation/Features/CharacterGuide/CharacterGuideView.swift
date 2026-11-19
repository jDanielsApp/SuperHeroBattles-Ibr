import SwiftUI

struct CharacterGuideView: View {
    let searchHeroes: SearchHeroesUseCase

    var body: some View {
        HeroSearchView(searchHeroes: searchHeroes)
    }
}

#Preview {
    NavigationStack {
        CharacterGuideView(
            searchHeroes: SearchHeroesUseCase(repository: UnconfiguredHeroRepository())
        )
    }
    .preferredColorScheme(.dark)
}

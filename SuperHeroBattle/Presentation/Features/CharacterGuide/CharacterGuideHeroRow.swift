import SwiftUI

/// Guide row: it picks (team picker sheet), requests the detail pane
/// (Duo inner screen) or pushes (compact), depending on the closures
/// the screen provides.
struct CharacterGuideHeroRow: View {
    let hero: Hero
    /// Catalog rows prefetch the next page when they appear.
    var prefetch: Bool
    var onSelect: (@MainActor () -> Void)?
    var onDetailRequested: (@MainActor () -> Void)?
    var onPrefetch: @MainActor (Hero) -> Void

    var body: some View {
        Group {
            if let onSelect {
                // Team picker sheet: the row selects and dismisses.
                Button {
                    onSelect()
                } label: {
                    HeroResultRow(hero: hero)
                }
                .buttonStyle(.plain)
            } else if let onDetailRequested {
                // Inner-screen split: the row asks the pane for the detail.
                Button {
                    onDetailRequested()
                } label: {
                    HeroResultRow(hero: hero)
                }
                .buttonStyle(.plain)
            } else {
                NavigationLink(value: hero) {
                    HeroResultRow(hero: hero)
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            guard prefetch else { return }
            onPrefetch(hero)
        }
    }
}

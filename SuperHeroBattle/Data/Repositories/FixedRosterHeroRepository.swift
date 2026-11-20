import Foundation

/// Repository backed by a fixed roster of synthetic heroes.
///
/// Only used when the app launches in fakes mode (`-uitest-fakes`) and in
/// previews. Its data is for testing and is never presented as if it came
/// from SuperHeroAPI.
nonisolated struct FixedRosterHeroRepository: HeroRepository {
    /// Synthetic roster with enough heroes to fill a 3 vs 3 without
    /// duplicates and with a variety of publishers and genders.
    static let roster: [Hero] = (1...12).map { index in
        Hero(
            id: String(index),
            name: "UITest Hero \(index)",
            biography: HeroBiography(
                fullName: "Test subject \(index)",
                publisher: index.isMultiple(of: 2) ? "DC Comics" : "Marvel",
                alignment: index.isMultiple(of: 3) ? .bad : .good
            ),
            appearance: HeroAppearance(
                gender: index.isMultiple(of: 2) ? "Male" : "Female"
            ),
            powerStats: PowerStats(
                intelligence: 40 + index,
                strength: 60,
                speed: 45,
                durability: nil,
                power: 55,
                combat: 50 + index
            )
        )
    }

    init() {}

    func search(query: String) async throws -> [Hero] {
        let normalized = SearchQueryNormalizer.normalizedQuery(query)
        guard !normalized.isEmpty else { return [] }

        return Self.roster.filter {
            $0.searchableText.localizedCaseInsensitiveContains(normalized)
        }
    }

    func hero(id: String) async throws -> Hero {
        guard let hero = Self.roster.first(where: { $0.id == id }) else {
            throw HeroRepositoryError.notFound
        }
        return hero
    }
}

import Foundation

nonisolated struct HeroFilter: Equatable, Sendable {
    var query: String
    var publisher: String?
    var gender: String?

    init(query: String = "", publisher: String? = nil, gender: String? = nil) {
        self.query = query
        self.publisher = publisher
        self.gender = gender
    }

    var hasCriteria: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || publisher != nil
            || gender != nil
    }
}

nonisolated struct FilterHeroesUseCase: Sendable {
    init() {}

    func execute(heroes: [Hero], filter: HeroFilter) -> [Hero] {
        let query = filter.query.trimmingCharacters(in: .whitespacesAndNewlines)

        return heroes.filter { hero in
            matches(hero: hero, query: query)
                && matches(value: hero.publisher, selection: filter.publisher)
                && matches(value: hero.gender, selection: filter.gender)
        }
    }

    private func matches(hero: Hero, query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return hero.searchableText.range(
            of: query,
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        ) != nil
    }

    private func matches(value: String?, selection: String?) -> Bool {
        guard let selection else { return true }
        guard let value else { return false }
        return value.compare(selection, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
    }
}

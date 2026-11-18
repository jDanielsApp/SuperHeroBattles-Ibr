import Foundation

/// Entidad de dominio que representa un superhéroe de SuperHeroAPI.
nonisolated struct Hero: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let biography: HeroBiography
    let appearance: HeroAppearance
    let work: HeroWork
    let connections: HeroConnections
    let powerStats: PowerStats
    let imageURL: URL?

    init(
        id: String,
        name: String,
        biography: HeroBiography = .unknown,
        appearance: HeroAppearance = .unknown,
        work: HeroWork = .unknown,
        connections: HeroConnections = .unknown,
        powerStats: PowerStats = .unknown,
        imageURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.biography = biography
        self.appearance = appearance
        self.work = work
        self.connections = connections
        self.powerStats = powerStats
        self.imageURL = imageURL
    }

    var fullName: String? { biography.fullName }
    var publisher: String? { biography.publisher }
    var alignment: HeroAlignment { biography.alignment }
    var gender: String? { appearance.gender }

    /// Texto plano utilizado por la búsqueda y los filtros locales.
    var searchableText: String {
        [
            name,
            biography.fullName,
            biography.alterEgos,
            biography.aliases.joined(separator: " "),
            biography.publisher,
            appearance.gender,
            appearance.race,
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }

    var snapshot: HeroSnapshot {
        HeroSnapshot(hero: self)
    }
}

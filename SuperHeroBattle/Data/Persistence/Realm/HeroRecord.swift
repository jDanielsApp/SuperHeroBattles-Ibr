import Foundation

/// Representación persistible y estable de `Hero`.
///
/// Se guarda como JSON dentro de Realm para no acoplar el esquema de persistencia
/// a los cambios internos de las entidades de dominio.
nonisolated struct HeroRecord: Codable, Sendable {
    let id: String
    let name: String
    let fullName: String?
    let alterEgos: String?
    let aliases: [String]
    let placeOfBirth: String?
    let firstAppearance: String?
    let publisher: String?
    let alignment: String
    let gender: String?
    let race: String?
    let height: [String]
    let weight: [String]
    let eyeColor: String?
    let hairColor: String?
    let occupation: String?
    let base: String?
    let groupAffiliation: String?
    let relatives: String?
    let intelligence: Int?
    let strength: Int?
    let speed: Int?
    let durability: Int?
    let power: Int?
    let combat: Int?
    let imageURL: String?

    init(hero: Hero) {
        id = hero.id
        name = hero.name
        fullName = hero.biography.fullName
        alterEgos = hero.biography.alterEgos
        aliases = hero.biography.aliases
        placeOfBirth = hero.biography.placeOfBirth
        firstAppearance = hero.biography.firstAppearance
        publisher = hero.biography.publisher
        alignment = hero.biography.alignment.rawValue
        gender = hero.appearance.gender
        race = hero.appearance.race
        height = hero.appearance.height
        weight = hero.appearance.weight
        eyeColor = hero.appearance.eyeColor
        hairColor = hero.appearance.hairColor
        occupation = hero.work.occupation
        base = hero.work.base
        groupAffiliation = hero.connections.groupAffiliation
        relatives = hero.connections.relatives

        let stats = hero.powerStats
        intelligence = stats[.intelligence]
        strength = stats[.strength]
        speed = stats[.speed]
        durability = stats[.durability]
        power = stats[.power]
        combat = stats[.combat]

        imageURL = hero.imageURL?.absoluteString
    }

    func makeHero() -> Hero {
        Hero(
            id: id,
            name: name,
            biography: HeroBiography(
                fullName: fullName,
                alterEgos: alterEgos,
                aliases: aliases,
                placeOfBirth: placeOfBirth,
                firstAppearance: firstAppearance,
                publisher: publisher,
                alignment: HeroAlignment(rawValue: alignment) ?? .unknown
            ),
            appearance: HeroAppearance(
                gender: gender,
                race: race,
                height: height,
                weight: weight,
                eyeColor: eyeColor,
                hairColor: hairColor
            ),
            work: HeroWork(
                occupation: occupation,
                base: base
            ),
            connections: HeroConnections(
                groupAffiliation: groupAffiliation,
                relatives: relatives
            ),
            powerStats: PowerStats(
                intelligence: intelligence,
                strength: strength,
                speed: speed,
                durability: durability,
                power: power,
                combat: combat
            ),
            imageURL: imageURL.flatMap(URL.init(string:))
        )
    }

    func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }

    static func decode(data: Data) throws -> HeroRecord {
        try JSONDecoder().decode(HeroRecord.self, from: data)
    }
}

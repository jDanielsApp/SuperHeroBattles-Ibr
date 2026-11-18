import Foundation

nonisolated struct HeroBiography: Hashable, Sendable {
    let fullName: String?
    let alterEgos: String?
    let aliases: [String]
    let placeOfBirth: String?
    let firstAppearance: String?
    let publisher: String?
    let alignment: HeroAlignment

    init(
        fullName: String? = nil,
        alterEgos: String? = nil,
        aliases: [String] = [],
        placeOfBirth: String? = nil,
        firstAppearance: String? = nil,
        publisher: String? = nil,
        alignment: HeroAlignment = .unknown
    ) {
        self.fullName = fullName
        self.alterEgos = alterEgos
        self.aliases = aliases
        self.placeOfBirth = placeOfBirth
        self.firstAppearance = firstAppearance
        self.publisher = publisher
        self.alignment = alignment
    }

    static let unknown = HeroBiography()
}

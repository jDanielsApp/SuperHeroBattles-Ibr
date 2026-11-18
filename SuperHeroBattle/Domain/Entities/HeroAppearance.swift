import Foundation

nonisolated struct HeroAppearance: Hashable, Sendable {
    let gender: String?
    let race: String?
    let height: [String]
    let weight: [String]
    let eyeColor: String?
    let hairColor: String?

    init(
        gender: String? = nil,
        race: String? = nil,
        height: [String] = [],
        weight: [String] = [],
        eyeColor: String? = nil,
        hairColor: String? = nil
    ) {
        self.gender = gender
        self.race = race
        self.height = height
        self.weight = weight
        self.eyeColor = eyeColor
        self.hairColor = hairColor
    }

    static let unknown = HeroAppearance()
}

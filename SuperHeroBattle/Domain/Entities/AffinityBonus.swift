import Foundation

nonisolated struct AffinityBonus: Identifiable, Equatable, Sendable {
    let heroAID: String
    let heroBID: String
    let bonus: Int
    let matchedAffiliations: [String]
    let matchedRelatives: [String]

    var id: String { "\(heroAID)-\(heroBID)" }
}

import Foundation

nonisolated struct CombatantScore: Identifiable, Equatable, Sendable {
    let hero: HeroSnapshot
    let baseScore: Double
    let luck: Int
    let totalScore: Double

    var id: String { hero.id }
}

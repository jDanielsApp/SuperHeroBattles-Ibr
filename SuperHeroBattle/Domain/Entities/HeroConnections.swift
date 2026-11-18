import Foundation

nonisolated struct HeroConnections: Hashable, Sendable {
    let affiliations: [String]
    let relatives: [String]

    init(affiliations: [String] = [], relatives: [String] = []) {
        self.affiliations = affiliations
        self.relatives = relatives
    }

    static let unknown = HeroConnections()
}

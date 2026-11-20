import Foundation

/// The character's connections. The API delivers free-form text and its
/// documentation recommends not interpreting it automatically, so it is kept as-is.
nonisolated struct HeroConnections: Hashable, Sendable {
    let groupAffiliation: String?
    let relatives: String?

    init(groupAffiliation: String? = nil, relatives: String? = nil) {
        self.groupAffiliation = groupAffiliation
        self.relatives = relatives
    }

    static let unknown = HeroConnections()
}

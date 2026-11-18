import Foundation

nonisolated struct HeroWork: Hashable, Sendable {
    let occupation: String?
    let base: String?

    init(occupation: String? = nil, base: String? = nil) {
        self.occupation = occupation
        self.base = base
    }

    static let unknown = HeroWork()
}

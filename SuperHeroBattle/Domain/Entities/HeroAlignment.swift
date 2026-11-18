import Foundation

nonisolated enum HeroAlignment: String, CaseIterable, Hashable, Sendable {
    case good
    case bad
    case neutral
    case unknown
}

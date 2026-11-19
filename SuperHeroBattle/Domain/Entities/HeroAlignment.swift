import Foundation

nonisolated enum HeroAlignment: String, CaseIterable, Hashable, Codable, Sendable {
    case good
    case bad
    case neutral
    case unknown
}

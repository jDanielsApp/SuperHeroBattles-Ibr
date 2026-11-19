import Foundation

nonisolated struct PowerStatsDTO: Decodable, Sendable {
    let intelligence: String?
    let strength: String?
    let speed: String?
    let durability: String?
    let power: String?
    let combat: String?
}

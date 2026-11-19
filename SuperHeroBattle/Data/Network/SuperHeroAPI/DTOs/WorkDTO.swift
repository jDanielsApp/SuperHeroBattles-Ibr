import Foundation

nonisolated struct WorkDTO: Decodable, Sendable {
    let occupation: String?
    let base: String?
}

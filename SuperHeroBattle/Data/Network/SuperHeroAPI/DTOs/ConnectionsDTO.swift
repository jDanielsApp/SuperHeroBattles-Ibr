import Foundation

nonisolated struct ConnectionsDTO: Decodable, Sendable {
    let groupAffiliation: String?
    let relatives: String?

    enum CodingKeys: String, CodingKey {
        case groupAffiliation = "group-affiliation"
        case relatives
    }
}

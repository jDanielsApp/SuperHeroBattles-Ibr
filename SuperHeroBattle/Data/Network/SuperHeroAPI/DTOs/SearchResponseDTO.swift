import Foundation

nonisolated struct SearchResponseDTO: Decodable, Sendable {
    let response: String?
    let error: String?
    let resultsFor: String?
    let results: [HeroDTO]?

    enum CodingKeys: String, CodingKey {
        case response
        case error
        case resultsFor = "results-for"
        case results
    }
}

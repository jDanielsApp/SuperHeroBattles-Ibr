import Foundation

/// Element of a search result or a detail lookup.
/// All fields are optional to tolerate partial responses.
nonisolated struct HeroDTO: Decodable, Sendable {
    let response: String?
    let error: String?
    let id: String?
    let name: String?
    let powerstats: PowerStatsDTO?
    let biography: BiographyDTO?
    let appearance: AppearanceDTO?
    let work: WorkDTO?
    let connections: ConnectionsDTO?
    let image: ImageDTO?
}

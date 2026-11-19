import Foundation

/// Elemento de un resultado de búsqueda o de una consulta de detalle.
/// Todos los campos son opcionales para tolerar respuestas parciales.
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

import Foundation

/// Conexiones del personaje. La API entrega texto libre y la documentación
/// recomienda no interpretarlo automáticamente, así que se conserva tal cual.
nonisolated struct HeroConnections: Hashable, Sendable {
    let groupAffiliation: String?
    let relatives: String?

    init(groupAffiliation: String? = nil, relatives: String? = nil) {
        self.groupAffiliation = groupAffiliation
        self.relatives = relatives
    }

    static let unknown = HeroConnections()
}

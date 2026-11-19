import Foundation

/// Configuración de la caché TTL de búsquedas.
nonisolated struct HeroSearchCacheConfiguration: Equatable, Sendable {
    static let minimumTimeToLive: TimeInterval = 120
    static let maximumTimeToLive: TimeInterval = 300
    static let `default` = HeroSearchCacheConfiguration(timeToLive: 180)

    let timeToLive: TimeInterval

    init(timeToLive: TimeInterval) {
        self.timeToLive = min(
            max(timeToLive, Self.minimumTimeToLive),
            Self.maximumTimeToLive
        )
    }
}

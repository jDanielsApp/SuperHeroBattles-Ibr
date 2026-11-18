import Foundation

/// Identifica cada uno de los seis PowerStats de SuperHeroAPI.
nonisolated enum PowerStatKind: String, CaseIterable, Identifiable, Hashable, Sendable {
    case intelligence
    case strength
    case speed
    case durability
    case power
    case combat

    var id: String { rawValue }
}

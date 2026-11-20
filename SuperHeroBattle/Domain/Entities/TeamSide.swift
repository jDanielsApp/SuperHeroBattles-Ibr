import Foundation

nonisolated enum TeamSide: String, CaseIterable, Identifiable, Sendable {
    case teamA
    case teamB

    var id: String { rawValue }
}

import Foundation

nonisolated enum TeamSide: String, CaseIterable, Identifiable, Sendable {
    case teamA
    case teamB

    var id: String { rawValue }

    var opponent: TeamSide {
        switch self {
        case .teamA: .teamB
        case .teamB: .teamA
        }
    }
}

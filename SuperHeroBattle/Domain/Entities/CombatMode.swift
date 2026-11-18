import Foundation

nonisolated enum CombatMode: String, CaseIterable, Identifiable, Sendable {
    case oneVsOne = "1v1"
    case twoVsTwo = "2v2"
    case threeVsThree = "3v3"

    var id: String { rawValue }

    var teamSize: Int {
        switch self {
        case .oneVsOne:
            1
        case .twoVsTwo:
            2
        case .threeVsThree:
            3
        }
    }
}

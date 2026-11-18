import Foundation

nonisolated enum NarrativeSource: String, Equatable, Sendable {
    case foundationModels
    case template
}

nonisolated struct CombatNarrative: Equatable, Sendable {
    let text: String
    let source: NarrativeSource
}

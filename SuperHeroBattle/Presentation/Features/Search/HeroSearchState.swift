import Foundation

nonisolated enum HeroSearchState: Equatable, Sendable {
    case idle
    case loading
    case empty
    case results([Hero])
    case failure(HeroSearchFailure)
}

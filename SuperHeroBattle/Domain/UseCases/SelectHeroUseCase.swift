import Foundation

nonisolated struct SelectHeroUseCase: Sendable {
    init() {}

    func execute(hero: Hero, slot: Int, in draft: TeamDraft) throws -> TeamDraft {
        var updated = draft
        try updated.assign(hero, at: slot)
        return updated
    }
}

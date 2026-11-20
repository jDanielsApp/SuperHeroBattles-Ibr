import Foundation

nonisolated enum TeamValidationError: Error, Equatable, Sendable {
    case invalidSlot
    case duplicateHero
}

/// Team draft with slots. Supports selecting, replacing, and clearing slots individually.
nonisolated struct TeamDraft: Equatable, Sendable {
    let side: TeamSide
    let mode: CombatMode
    private(set) var slots: [Hero?]

    init(side: TeamSide, mode: CombatMode) {
        self.side = side
        self.mode = mode
        self.slots = Array(repeating: nil, count: mode.teamSize)
    }

    var heroes: [Hero] {
        slots.compactMap { $0 }
    }

    var heroIDs: [String] {
        heroes.map(\.id)
    }

    var isComplete: Bool {
        slots.allSatisfy { $0 != nil } && Set(heroIDs).count == slots.count
    }

    func hero(in slot: Int) -> Hero? {
        guard slots.indices.contains(slot) else { return nil }
        return slots[slot]
    }

    func firstEmptySlot() -> Int? {
        slots.firstIndex(where: { $0 == nil })
    }

    func contains(heroID: String) -> Bool {
        slots.contains(where: { $0?.id == heroID })
    }

    mutating func assign(_ hero: Hero, at slot: Int) throws {
        guard slots.indices.contains(slot) else {
            throw TeamValidationError.invalidSlot
        }

        if slots[slot]?.id == hero.id {
            return
        }

        guard !contains(heroID: hero.id) else {
            throw TeamValidationError.duplicateHero
        }

        slots[slot] = hero
    }

    mutating func clear(at slot: Int) throws {
        guard slots.indices.contains(slot) else {
            throw TeamValidationError.invalidSlot
        }
        slots[slot] = nil
    }

    mutating func clear(heroID: String) {
        guard let slot = slots.firstIndex(where: { $0?.id == heroID }) else { return }
        slots[slot] = nil
    }
}

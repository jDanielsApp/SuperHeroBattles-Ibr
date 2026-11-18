import Foundation

nonisolated protocol RandomHeroPicker: Sendable {
    func pick(from heroes: [Hero], excluding heroIDs: Set<String>) -> Hero?
}

nonisolated struct SystemRandomHeroPicker: RandomHeroPicker {
    init() {}

    func pick(from heroes: [Hero], excluding heroIDs: Set<String>) -> Hero? {
        heroes
            .filter { !heroIDs.contains($0.id) }
            .randomElement()
    }
}

import Foundation

/// Source of each combatant's luck. Injectable for deterministic tests:
/// luck is the combat engine's only source of randomness.
nonisolated protocol LuckProvider: Sendable {
    /// Luck roll in the closed range 7...77.
    func nextLuck() -> Int
}

/// System luck. Uses Swift's global RNG, which is thread-safe.
nonisolated struct SystemLuckProvider: LuckProvider {
    static let luckRange: ClosedRange<Int> = 7...77

    init() {}

    func nextLuck() -> Int {
        Int.random(in: Self.luckRange)
    }
}

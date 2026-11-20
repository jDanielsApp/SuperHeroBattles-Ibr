import Foundation
@testable import SuperHeroBattle

/// Luck provider with a fixed sequence. Once exhausted, it repeats the last value.
///
/// Test-only: it keeps mutable state without a lock because the combat
/// engine consumes it synchronously from a single context.
final class SequenceLuckProvider: LuckProvider, @unchecked Sendable {
    private let values: [Int]
    private var index = 0

    init(_ values: [Int]) {
        self.values = values
    }

    func nextLuck() -> Int {
        guard !values.isEmpty else { return SystemLuckProvider.luckRange.lowerBound }
        let value = values[min(index, values.count - 1)]
        if index < values.count - 1 {
            index += 1
        }
        return value
    }
}

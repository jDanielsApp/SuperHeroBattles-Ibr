import Foundation

/// A character's PowerStats. A `nil` value means unknown, never zero.
nonisolated struct PowerStats: Hashable, Sendable {
    private let values: [PowerStatKind: Int]

    init(
        intelligence: Int? = nil,
        strength: Int? = nil,
        speed: Int? = nil,
        durability: Int? = nil,
        power: Int? = nil,
        combat: Int? = nil
    ) {
        let candidates: [(PowerStatKind, Int?)] = [
            (.intelligence, intelligence),
            (.strength, strength),
            (.speed, speed),
            (.durability, durability),
            (.power, power),
            (.combat, combat),
        ]

        var values: [PowerStatKind: Int] = [:]
        for (kind, value) in candidates {
            guard let value, (0...100).contains(value) else { continue }
            values[kind] = value
        }
        self.values = values
    }

    subscript(kind: PowerStatKind) -> Int? {
        values[kind]
    }

    var knownValues: [Int] {
        PowerStatKind.allCases.compactMap { values[$0] }
    }

    var knownCount: Int {
        values.count
    }

    /// Arithmetic mean of the known values. Returns zero when there are no known values.
    var baseScore: Double {
        guard !values.isEmpty else { return 0 }
        return Double(knownValues.reduce(0, +)) / Double(values.count)
    }

    var isUnknown: Bool {
        values.isEmpty
    }

    static let unknown = PowerStats()
}

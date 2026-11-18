import XCTest
@testable import SuperHeroBattle

final class PowerStatsTests: XCTestCase {
    func testBaseScoreAveragesKnownStats() {
        let stats = PowerStats(intelligence: 100, strength: 50, combat: 30)

        XCTAssertEqual(stats.baseScore, 60, accuracy: 0.001)
        XCTAssertEqual(stats.knownCount, 3)
    }

    func testUnknownStatsAreExcludedFromAverage() {
        let stats = PowerStats(intelligence: 90, strength: nil, speed: 60, durability: nil)

        XCTAssertEqual(stats.baseScore, 75, accuracy: 0.001)
        XCTAssertEqual(stats.knownValues, [90, 60])
    }

    func testAllUnknownStatsReturnZero() {
        let stats = PowerStats()

        XCTAssertTrue(stats.isUnknown)
        XCTAssertEqual(stats.baseScore, 0, accuracy: 0.001)
        XCTAssertTrue(stats.knownValues.isEmpty)
    }

    func testOutOfRangeValuesAreTreatedAsUnknown() {
        let stats = PowerStats(intelligence: 150, strength: 80, speed: -10)

        XCTAssertNil(stats[.intelligence])
        XCTAssertNil(stats[.speed])
        XCTAssertEqual(stats[.strength], 80)
        XCTAssertEqual(stats.baseScore, 80, accuracy: 0.001)
    }
}

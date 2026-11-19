import RealmSwift
import XCTest
@testable import SuperHeroBattle

@MainActor
final class RealmCombatHistoryRepositoryTests: XCTestCase {
    func testSaveAndReadRoundTripsTheFullRecord() async throws {
        let repository = try makeRepository()
        let record = makeRecord(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            date: Date(timeIntervalSince1970: 1_000_000),
            outcome: .winner(.teamA),
            narration: "Simulación ficticia: Batman gana.",
            source: .foundationModels
        )

        try await repository.save(record)

        let stored = try await repository.record(id: record.id)
        XCTAssertEqual(stored, record)
    }

    func testDrawOutcomeRoundTrips() async throws {
        let repository = try makeRepository()
        let record = makeRecord(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            date: Date(timeIntervalSince1970: 2_000_000),
            outcome: .draw,
            narration: "Empate total.",
            source: .template
        )

        try await repository.save(record)

        let stored = try await repository.record(id: record.id)
        XCTAssertEqual(stored?.outcome, .draw)
        XCTAssertEqual(stored?.narrationSource, .template)
    }

    func testAllSortsByNewestFirst() async throws {
        let repository = try makeRepository()
        let base = Date(timeIntervalSince1970: 1_000_000)
        let records = (0..<3).map { index in
            makeRecord(
                date: base.addingTimeInterval(TimeInterval(index * 100)),
                outcome: .draw,
                narration: "Combate \(index)",
                source: .template
            )
        }
        for record in records {
            try await repository.save(record)
        }

        let all = try await repository.all()

        XCTAssertEqual(all.map(\.narration), ["Combate 2", "Combate 1", "Combate 0"])
    }

    func testSaveWithSameIDUpdatesTheRecord() async throws {
        let repository = try makeRepository()
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        try await repository.save(makeRecord(id: id, outcome: .draw, narration: "Primera", source: .template))
        try await repository.save(makeRecord(id: id, outcome: .winner(.teamB), narration: "Segunda", source: .template))

        let all = try await repository.all()

        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.narration, "Segunda")
        XCTAssertEqual(all.first?.outcome, .winner(.teamB))
    }

    func testUnknownIDReturnsNil() async throws {
        let repository = try makeRepository()

        let missing = try await repository.record(id: UUID())

        XCTAssertNil(missing)
    }

    func testDeleteRemovesOnlyThatRecord() async throws {
        let repository = try makeRepository()
        let kept = makeRecord(outcome: .draw, narration: "Se queda", source: .template)
        let removed = makeRecord(outcome: .draw, narration: "Se va", source: .template)
        try await repository.save(kept)
        try await repository.save(removed)

        try await repository.delete(id: removed.id)

        let all = try await repository.all()
        XCTAssertEqual(all.map(\.narration), ["Se queda"])
    }

    func testDeleteAllEmptiesTheHistory() async throws {
        let repository = try makeRepository()
        try await repository.save(makeRecord(outcome: .draw, narration: "Uno", source: .template))
        try await repository.save(makeRecord(outcome: .draw, narration: "Dos", source: .template))

        try await repository.deleteAll()

        let all = try await repository.all()
        XCTAssertTrue(all.isEmpty)
    }

    // MARK: - Helpers

    private func makeRepository() throws -> RealmCombatHistoryRepository {
        try RealmCombatHistoryRepository(
            configuration: RealmStore.configuration(
                inMemory: true,
                inMemoryIdentifier: "history-\(UUID().uuidString)"
            )
        )
    }

    private func makeRecord(
        id: UUID = UUID(),
        date: Date = Date(timeIntervalSince1970: 1_000_000),
        outcome: CombatOutcome,
        narration: String,
        source: NarrativeSource
    ) -> CombatRecord {
        CombatRecord(
            id: id,
            date: date,
            mode: .twoVsTwo,
            teamA: [
                HeroSnapshot(
                    id: "70",
                    name: "Batman",
                    fullName: "Bruce Wayne",
                    publisher: "DC Comics",
                    alignment: .good,
                    imageURL: URL(string: "https://example.com/batman.jpg")
                ),
                HeroSnapshot(id: "2", name: "Robin")
            ],
            teamB: [
                HeroSnapshot(id: "370", name: "Joker", publisher: "DC Comics", alignment: .bad),
                HeroSnapshot(id: "4", name: "Harley Quinn")
            ],
            outcome: outcome,
            narration: narration,
            narrationSource: source
        )
    }
}

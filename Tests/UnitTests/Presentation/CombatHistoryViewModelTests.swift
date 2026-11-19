import XCTest
@testable import SuperHeroBattle

@MainActor
final class CombatHistoryViewModelTests: XCTestCase {
    func testLoadPublishesEmptyStateWhenHistoryIsEmpty() async {
        let viewModel = makeViewModel()

        await viewModel.load()

        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.loadFailed)
    }

    func testLoadPublishesRecordsNewestFirst() async {
        let repository = InMemoryCombatHistoryRepository()
        let base = Date(timeIntervalSince1970: 1_000_000)
        for index in 0..<3 {
            try? await repository.save(
                makeRecord(
                    date: base.addingTimeInterval(TimeInterval(index * 100)),
                    narration: "Combate \(index)"
                )
            )
        }
        let viewModel = makeViewModel(repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.records.map(\.narration), ["Combate 2", "Combate 1", "Combate 0"])
    }

    func testDeleteRemovesOnlyThatRecord() async {
        let repository = InMemoryCombatHistoryRepository()
        let kept = makeRecord(narration: "Se queda")
        let removed = makeRecord(narration: "Se va")
        try? await repository.save(kept)
        try? await repository.save(removed)
        let viewModel = makeViewModel(repository: repository)
        await viewModel.load()

        await viewModel.delete(record: removed)

        XCTAssertEqual(viewModel.records.map(\.narration), ["Se queda"])
    }

    func testDeleteAllEmptiesTheList() async {
        let repository = InMemoryCombatHistoryRepository()
        try? await repository.save(makeRecord(narration: "Uno"))
        try? await repository.save(makeRecord(narration: "Dos"))
        let viewModel = makeViewModel(repository: repository)
        await viewModel.load()

        await viewModel.deleteAll()

        XCTAssertTrue(viewModel.isEmpty)
    }

    func testLoadFailureIsExposedForRetry() async {
        let viewModel = makeViewModel(repository: FailingHistoryRepository())

        await viewModel.load()

        XCTAssertTrue(viewModel.loadFailed)

        // El reintento con el mismo repositorio fallido no repone datos.
        await viewModel.retry()
        XCTAssertTrue(viewModel.loadFailed)
    }

    // MARK: - Helpers

    private func makeViewModel(
        repository: any CombatHistoryRepository = InMemoryCombatHistoryRepository()
    ) -> CombatHistoryViewModel {
        CombatHistoryViewModel(
            getHistory: GetCombatHistoryUseCase(repository: repository),
            deleteHistory: DeleteCombatHistoryUseCase(repository: repository)
        )
    }

    private func makeRecord(
        date: Date = Date(timeIntervalSince1970: 1_000_000),
        narration: String
    ) -> CombatRecord {
        CombatRecord(
            date: date,
            mode: .oneVsOne,
            teamA: [HeroSnapshot(id: "1", name: "Batman")],
            teamB: [HeroSnapshot(id: "2", name: "Joker")],
            outcome: .draw,
            narration: narration,
            narrationSource: .template
        )
    }
}

/// Repositorio cuyo `all()` siempre falla.
private struct FailingHistoryRepository: CombatHistoryRepository {
    func save(_ record: CombatRecord) async throws {}

    func all() async throws -> [CombatRecord] {
        throw HeroRepositoryError.transport
    }

    func record(id: UUID) async throws -> CombatRecord? { nil }

    func delete(id: UUID) async throws {}

    func deleteAll() async throws {}
}

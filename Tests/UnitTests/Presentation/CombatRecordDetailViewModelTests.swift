import XCTest
@testable import SuperHeroBattle

@MainActor
final class CombatRecordDetailViewModelTests: XCTestCase {
    func testDeleteRemovesOnlyThatRecordAndMarksItDeleted() async {
        let repository = InMemoryCombatHistoryRepository()
        let kept = makeRecord(narration: "Se queda")
        let removed = makeRecord(narration: "Se va")
        try? await repository.save(kept)
        try? await repository.save(removed)
        let viewModel = makeViewModel(record: removed, repository: repository)

        await viewModel.delete()

        let remaining = try? await repository.all()
        XCTAssertEqual(remaining?.map(\.narration), ["Se queda"])
        XCTAssertTrue(viewModel.isDeleted, "Tras borrar, la vista debe volver al listado")
        XCTAssertFalse(viewModel.isDeleting)
        XCTAssertFalse(viewModel.canDelete, "Un combate borrado no se puede borrar dos veces")
    }

    func testDeletedRecordCannotBeDeletedTwice() async {
        let repository = CountingDeleteHistoryRepository()
        let viewModel = makeViewModel(record: makeRecord(), repository: repository)

        await viewModel.delete()
        await viewModel.delete()

        let deletions = await repository.deletionCount()
        XCTAssertEqual(deletions, 1, "El segundo intento no debe llegar al repositorio")
    }

    func testFailedDeleteAllowsRetryWithoutNavigating() async {
        let repository = FailingDeleteHistoryRepository()
        let viewModel = makeViewModel(record: makeRecord(), repository: repository)

        await viewModel.delete()

        XCTAssertFalse(viewModel.isDeleted, "Un fallo de Realm no marca el combate como borrado")
        XCTAssertFalse(viewModel.isDeleting)
        XCTAssertTrue(viewModel.canDelete, "El usuario puede reintentar tras un fallo")
    }

    // MARK: - Helpers

    private func makeViewModel(
        record: CombatRecord,
        repository: any CombatHistoryRepository
    ) -> CombatRecordDetailViewModel {
        CombatRecordDetailViewModel(
            record: record,
            deleteHistory: DeleteCombatHistoryUseCase(repository: repository)
        )
    }

    private func makeRecord(
        narration: String = "Combate guardado"
    ) -> CombatRecord {
        CombatRecord(
            date: Date(timeIntervalSince1970: 1_000_000),
            mode: .oneVsOne,
            teamA: [HeroSnapshot(id: "1", name: "Batman")],
            teamB: [HeroSnapshot(id: "2", name: "Joker")],
            outcome: .draw,
            narration: narration,
            narrationSource: .template
        )
    }
}

/// Repositorio que cuenta los borrados para verificar el guarda de doble intento.
private actor CountingDeleteHistoryRepository: CombatHistoryRepository {
    private var deletions = 0

    func save(_ record: CombatRecord) async throws {}

    func all() async throws -> [CombatRecord] { [] }

    func record(id: UUID) async throws -> CombatRecord? { nil }

    func delete(id: UUID) async throws {
        deletions += 1
    }

    func deleteAll() async throws {}

    func deletionCount() -> Int {
        deletions
    }
}

/// Repositorio cuyo `delete` siempre falla: cubre el reintento silencioso.
private struct FailingDeleteHistoryRepository: CombatHistoryRepository {
    func save(_ record: CombatRecord) async throws {}

    func all() async throws -> [CombatRecord] { [] }

    func record(id: UUID) async throws -> CombatRecord? { nil }

    func delete(id: UUID) async throws {
        throw HeroRepositoryError.transport
    }

    func deleteAll() async throws {}
}

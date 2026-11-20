import Foundation

/// Estado de la pantalla de historial de combates.
@MainActor
@Observable
final class CombatHistoryViewModel {
    private(set) var records: [CombatRecord] = []
    private(set) var isLoading = false
    private(set) var loadFailed = false

    private let getHistory: GetCombatHistoryUseCase
    private let deleteHistory: DeleteCombatHistoryUseCase

    init(
        getHistory: GetCombatHistoryUseCase,
        deleteHistory: DeleteCombatHistoryUseCase
    ) {
        self.getHistory = getHistory
        self.deleteHistory = deleteHistory
    }

    var isEmpty: Bool {
        records.isEmpty
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            records = try await getHistory.execute()
            loadFailed = false
        } catch is CancellationError {
            // Sin cambios: la vista desapareció o se recargó.
        } catch {
            loadFailed = true
        }
    }

    func retry() async {
        loadFailed = false
        await load()
    }

    func deleteAll() async {
        do {
            try await deleteHistory.executeAll()
            records.removeAll()
        } catch {
            // Sin cambios: el listado conserva los registros.
        }
    }
}

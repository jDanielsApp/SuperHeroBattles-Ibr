import Foundation

/// State for the combat history screen.
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
            // No state change: the view disappeared or the load restarted.
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
            // No state change: the list keeps its records.
        }
    }
}

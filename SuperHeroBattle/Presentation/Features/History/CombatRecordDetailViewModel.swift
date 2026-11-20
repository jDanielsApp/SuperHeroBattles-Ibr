import Foundation

/// State for a saved combat's detail.
///
/// Individual deletion lives here: the user taps a combat in the list and
/// the detail offers a delete button with a confirmation alert. After
/// deleting, the view dismisses and the list reloads on reappearance. A
/// Realm failure is silent: the record stays on screen and the user can
/// retry.
@MainActor
@Observable
final class CombatRecordDetailViewModel {
    let record: CombatRecord
    private(set) var isDeleting = false
    private(set) var isDeleted = false

    private let deleteHistory: DeleteCombatHistoryUseCase

    init(record: CombatRecord, deleteHistory: DeleteCombatHistoryUseCase) {
        self.record = record
        self.deleteHistory = deleteHistory
    }

    /// The button is disabled while deleting and after deletion.
    var canDelete: Bool {
        !isDeleting && !isDeleted
    }

    /// Deletes the combat after the user confirms. Silent on Realm
    /// failures: the combat stays on screen and can be retried.
    func delete() async {
        guard canDelete else { return }

        isDeleting = true
        defer { isDeleting = false }

        do {
            try await deleteHistory.execute(id: record.id)
        } catch {
            // Silent failure: no navigation and no deleted state.
            return
        }

        isDeleted = true
    }
}

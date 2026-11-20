import Foundation

/// Estado del detalle de un combate guardado.
///
/// El borrado individual vive aquí: el usuario presiona el combate en el
/// listado y el detalle ofrece el botón de eliminar con alerta de
/// confirmación. Tras borrar, la vista hace `dismiss` y el listado se
/// recarga solo al reaparecer. Un fallo de Realm es silencioso: el
/// registro sigue en pantalla y el usuario puede reintentar.
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

    /// El botón se deshabilita durante el borrado y tras haber borrado.
    var canDelete: Bool {
        !isDeleting && !isDeleted
    }

    /// Elimina el combate tras la confirmación del usuario. Silencioso
    /// ante fallos de Realm: el combate sigue en pantalla y se puede
    /// reintentar.
    func delete() async {
        guard canDelete else { return }

        isDeleting = true
        defer { isDeleting = false }

        do {
            try await deleteHistory.execute(id: record.id)
        } catch {
            // Fallo silencioso: sin navegación ni estado borrado.
            return
        }

        isDeleted = true
    }
}

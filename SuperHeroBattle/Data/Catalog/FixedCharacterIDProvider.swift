import Foundation

/// Proveedor fijo de IDs para UI tests y previews.
///
/// Nunca sustituye al índice real: solo se inyecta cuando la app arranca
/// en modo fakes (`-uitest-fakes`).
nonisolated struct FixedCharacterIDProvider: CharacterIDProviding {
    let ids: [String]

    init(ids: [String]) {
        self.ids = ids
    }

    func characterIDs() throws -> [String] {
        ids
    }
}

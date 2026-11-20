import Foundation

/// Fixed ID provider for UI tests and previews.
///
/// Never replaces the real index: it is only injected when the app
/// launches in fakes mode (`-uitest-fakes`).
nonisolated struct FixedCharacterIDProvider: CharacterIDProviding {
    let ids: [String]

    init(ids: [String]) {
        self.ids = ids
    }

    func characterIDs() throws -> [String] {
        ids
    }
}

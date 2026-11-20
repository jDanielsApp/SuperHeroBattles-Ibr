import Foundation
@testable import SuperHeroBattle

/// Controllable ID provider for tests.
nonisolated struct StubCharacterIDProvider: CharacterIDProviding {
    let ids: [String]
    let error: CharacterIDProviderError?

    init(ids: [String] = [], error: CharacterIDProviderError? = nil) {
        self.ids = ids
        self.error = error
    }

    func characterIDs() throws -> [String] {
        if let error {
            throw error
        }
        return ids
    }
}

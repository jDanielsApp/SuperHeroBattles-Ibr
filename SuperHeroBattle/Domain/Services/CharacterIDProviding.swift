import Foundation

/// Source of the character ID index bundled with the app.
nonisolated protocol CharacterIDProviding: Sendable {
    /// Returns the IDs in ascending order, without duplicates.
    func characterIDs() throws -> [String]
}

/// Errors thrown while reading the local ID index.
nonisolated enum CharacterIDProviderError: Error, Equatable, Sendable {
    case resourceMissing
    case unreadable
    case invalidFormat
    case empty
}

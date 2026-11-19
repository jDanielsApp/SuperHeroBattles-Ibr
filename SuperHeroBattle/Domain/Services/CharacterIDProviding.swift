import Foundation

/// Fuente del índice de IDs de personajes empaquetado con la app.
nonisolated protocol CharacterIDProviding: Sendable {
    /// Devuelve los IDs en orden ascendente, sin duplicados.
    func characterIDs() throws -> [String]
}

/// Errores al leer el índice local de IDs.
nonisolated enum CharacterIDProviderError: Error, Equatable, Sendable {
    case resourceMissing
    case unreadable
    case invalidFormat
    case empty
}

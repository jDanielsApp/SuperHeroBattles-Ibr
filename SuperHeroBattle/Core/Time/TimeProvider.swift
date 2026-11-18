import Foundation

/// Fuente de tiempo inyectable para que la expiración de la caché sea determinista en tests.
nonisolated protocol TimeProvider: Sendable {
    var now: Date { get }
}

nonisolated struct SystemTimeProvider: TimeProvider {
    init() {}

    var now: Date {
        Date()
    }
}

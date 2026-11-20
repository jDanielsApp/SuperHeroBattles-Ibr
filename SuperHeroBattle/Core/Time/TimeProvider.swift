import Foundation

/// Injectable time source that makes cache expiration deterministic in tests.
nonisolated protocol TimeProvider: Sendable {
    var now: Date { get }
}

nonisolated struct SystemTimeProvider: TimeProvider {
    init() {}

    var now: Date {
        Date()
    }
}

import Foundation
@testable import SuperHeroBattle

/// Controllable clock for cache tests.
nonisolated final class FakeTimeProvider: TimeProvider, @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date

    init(now: Date = Date(timeIntervalSince1970: 1_000_000)) {
        self.current = now
    }

    var now: Date {
        lock.lock()
        defer { lock.unlock() }
        return current
    }

    func advance(by interval: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        current = current.addingTimeInterval(interval)
    }
}

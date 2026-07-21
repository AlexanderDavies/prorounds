import Foundation

/// A deterministic `TimeSource` for tests. Time never advances on its own — the test drives it
/// with ``advance(by:)``. Work suspended in ``sleep(until:)`` resumes exactly when the fake's
/// instant reaches or passes its deadline, so an entire workout can be verified in microseconds
/// with no real elapsed time (guide §14.1).
///
/// Thread-safe via an internal lock; safe to share across the awaiting task and the advancing test.
public final class FakeTimeSource: TimeSource, @unchecked Sendable {
    private let lock = NSLock()
    private var current: ContinuousClock.Instant
    private var sleepers: [Sleeper] = []
    private var tickContinuations: [AsyncStream<ContinuousClock.Instant>.Continuation] = []

    private struct Sleeper {
        let deadline: ContinuousClock.Instant
        let continuation: CheckedContinuation<Void, Error>
    }

    /// Creates a fake starting at `start` (defaults to the real monotonic now, purely as an origin).
    public init(start: ContinuousClock.Instant = ContinuousClock().now) {
        self.current = start
    }

    public var now: ContinuousClock.Instant {
        lock.lock(); defer { lock.unlock() }
        return current
    }

    /// Number of tasks currently suspended in `sleep(until:)`. Exposed so tests can wait for a
    /// sleeper to register before advancing, keeping the fake fully deterministic.
    public var pendingSleeperCount: Int {
        lock.lock(); defer { lock.unlock() }
        return sleepers.count
    }

    /// Moves the clock forward by exactly `duration` and resumes any sleeper whose deadline is now due.
    public func advance(by duration: Duration) {
        lock.lock()
        current = current.advanced(by: duration)
        let due = sleepers.filter { $0.deadline <= current }
        sleepers.removeAll { $0.deadline <= current }
        lock.unlock()
        // Resume outside the lock so a resumed task can call back in without deadlocking.
        for sleeper in due { sleeper.continuation.resume() }
    }

    public func sleep(until deadline: ContinuousClock.Instant) async throws {
        try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            if deadline <= current {
                lock.unlock()
                continuation.resume()
            } else {
                sleepers.append(Sleeper(deadline: deadline, continuation: continuation))
                lock.unlock()
            }
        }
    }

    public func ticks(interval: Duration) -> AsyncStream<ContinuousClock.Instant> {
        AsyncStream { continuation in
            lock.lock()
            tickContinuations.append(continuation)
            lock.unlock()
        }
    }

    /// Yields the current instant to every tick stream. The fake emits ticks only when the test
    /// asks — never on its own — so a workout is driven deterministically.
    public func emitTick() {
        lock.lock()
        let continuations = tickContinuations
        let instant = current
        lock.unlock()
        for continuation in continuations { continuation.yield(instant) }
    }

    /// Convenience: advance the clock and emit a tick at the new instant.
    public func advanceAndTick(by duration: Duration) {
        advance(by: duration)
        emitTick()
    }
}

import Foundation

/// Production `TimeSource` backed by a monotonic `ContinuousClock`. Instants never move
/// backward and are unaffected by wall-clock/timezone changes or NTP adjustments.
public struct RealTimeSource: TimeSource {
    private let clock = ContinuousClock()

    public init() {}

    public var now: ContinuousClock.Instant { clock.now }

    public func sleep(until deadline: ContinuousClock.Instant) async throws {
        try await clock.sleep(until: deadline)
    }

    public func ticks(interval: Duration) -> AsyncStream<ContinuousClock.Instant> {
        let clock = clock
        return AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    do {
                        try await clock.sleep(for: interval)
                    } catch {
                        break // cancelled
                    }
                    continuation.yield(clock.now)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

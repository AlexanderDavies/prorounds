import Foundation

/// The injectable clock seam. Every timing-sensitive type reads time only through a
/// `TimeSource` (by constructor injection) rather than calling a global clock or `Date()`,
/// so behaviour can be driven deterministically in tests via `FakeTimeSource`.
///
/// Instants are `ContinuousClock.Instant` — monotonic and unaffected by wall-clock changes —
/// which is the basis for the timer engine's *deadline*-based design (guide §7.2): the engine
/// awaits `sleep(until:)` on a computed deadline rather than accumulating ticks, so it never drifts.
public protocol TimeSource: Sendable {
    /// The current monotonic instant. Never moves backward.
    var now: ContinuousClock.Instant { get }

    /// Suspends until `deadline` is reached (or the task is cancelled).
    func sleep(until deadline: ContinuousClock.Instant) async throws

    /// A stream of monotonic instants (~10–20 Hz) a consumer drives smooth display updates from,
    /// without polling a global clock. The production source emits on a repeating timer; the fake
    /// lets a test emit ticks by hand so a whole workout is driven deterministically (guide §7.3).
    func ticks(interval: Duration) -> AsyncStream<ContinuousClock.Instant>
}

public extension TimeSource {
    /// Convenience: suspend for a relative `duration` from `now`.
    func sleep(for duration: Duration) async throws {
        try await sleep(until: now.advanced(by: duration))
    }
}

import Foundation

/// The phase of a running workout. The sequence is exactly `preparing → (round → resting) × N`
/// with **no resting after the final round** (invariant §0.6.3). `preparing` is skipped when prep
/// is zero.
public enum WorkoutPhase: Equatable, Sendable {
    case preparing
    case round(index: Int)         // 1-based
    case resting(afterRound: Int)  // never emitted after the final round
    case finished
}

/// An immutable, `Sendable` view of the engine's state at an instant. Carries both `remaining` and
/// `elapsedInPhase` so the display can show either count direction without the engine branching on
/// it (guide §7.6).
public struct WorkoutSnapshot: Equatable, Sendable {
    public let phase: WorkoutPhase
    public let remaining: Duration
    public let elapsedInPhase: Duration
    public let elapsedTotal: Duration
    public let totalDuration: Duration
    public let roundCount: Int
    public let isPaused: Bool
    /// Whether the timeline has begun — false before `start()` and after `reset()`, true once running.
    /// Lets the display distinguish an idle (ready) screen from a running one (§ workout-runtime).
    public let started: Bool

    public init(
        phase: WorkoutPhase,
        remaining: Duration,
        elapsedInPhase: Duration,
        elapsedTotal: Duration,
        totalDuration: Duration,
        roundCount: Int,
        isPaused: Bool,
        started: Bool = false
    ) {
        self.phase = phase
        self.remaining = remaining
        self.elapsedInPhase = elapsedInPhase
        self.elapsedTotal = elapsedTotal
        self.totalDuration = totalDuration
        self.roundCount = roundCount
        self.isPaused = isPaused
        self.started = started
    }
}

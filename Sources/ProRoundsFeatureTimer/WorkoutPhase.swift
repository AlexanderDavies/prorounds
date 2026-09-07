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
/// The coaching call currently being said, ready to render.
///
/// Strings only. The timer module never learns where they came from, which is what keeps it free of
/// any dependency on the coaching module — and therefore unable to reach the entitlement.
public struct CoachCallDisplay: Equatable, Sendable {
    /// The prominent line — the call named in words.
    public let primary: String
    /// The same call in the other convention, shown smaller above. Nil when the call names no
    /// punches and so has only one rendering.
    public let secondary: String?
    /// A qualifier shown beneath, kept apart so the view can set it off.
    public let modifier: String?

    public init(primary: String, secondary: String?, modifier: String?) {
        self.primary = primary
        self.secondary = secondary
        self.modifier = modifier
    }

    /// One phrase for assistive technology.
    ///
    /// Deliberately omits the second convention: it exists to teach the mapping visually, and read
    /// aloud it would just repeat the call in numbers. The modifier is joined in, because
    /// "Jab Cross" and "to the body" announced as separate fragments loses the instruction.
    public var accessibleDescription: String {
        guard let modifier else { return primary }
        return "\(primary), \(modifier)"
    }
}

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
    /// The coaching call being said, or nil when the coach is silent — which is every moment of an
    /// uncoached workout, and every rest and prep of a coached one.
    public let currentCall: CoachCallDisplay?

    public init(
        phase: WorkoutPhase,
        remaining: Duration,
        elapsedInPhase: Duration,
        elapsedTotal: Duration,
        totalDuration: Duration,
        roundCount: Int,
        isPaused: Bool,
        started: Bool = false,
        currentCall: CoachCallDisplay? = nil
    ) {
        self.phase = phase
        self.remaining = remaining
        self.elapsedInPhase = elapsedInPhase
        self.elapsedTotal = elapsedTotal
        self.totalDuration = totalDuration
        self.roundCount = roundCount
        self.isPaused = isPaused
        self.started = started
        self.currentCall = currentCall
    }
}

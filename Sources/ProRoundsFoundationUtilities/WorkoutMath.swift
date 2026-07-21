import Foundation

/// The single source of truth for values *derived* from a workout configuration —
/// its total duration and its auto-generated name (guide §6.5, invariant §0.4 DRY).
/// Every screen that shows a total or a default name calls these; there is no second
/// implementation. Inputs are primitives so this Foundation module stays free of higher-layer
/// domain types; callers pass their configuration's fields.
public enum WorkoutMath {
    /// Total workout time: `round×N + rest×(N−1)` — rounds + rest, with **no rest after the final
    /// round** (invariant §0.6.3). Prep is a lead-in and is excluded. Zero/negative rounds yields zero.
    public static func totalDuration(
        round: Duration,
        rest: Duration,
        rounds: Int
    ) -> Duration {
        guard rounds > 0 else { return .zero }
        return round * rounds + rest * (rounds - 1)
    }

    /// A meaningful default configuration name derived from the workout type, round count, round
    /// duration and rest period — e.g. "Heavy Bag · 12×3min / 1min rest". Used only when the user
    /// has not supplied a custom name.
    public static func autoName(
        workoutTypeName: String,
        rounds: Int,
        round: Duration,
        rest: Duration
    ) -> String {
        let roundText = DurationFormat.compactMinutes(round)
        let restText = DurationFormat.compactMinutes(rest)
        return "\(workoutTypeName) · \(rounds)×\(roundText) / \(restText) rest"
    }
}

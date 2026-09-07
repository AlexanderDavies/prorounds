import Foundation
import ProRoundsFoundationUtilities

/// The immutable domain value type describing a workout configuration. Persistence (the SwiftData
/// entity + repository) and validation rules are added in a later change; this is the in-memory
/// domain the timer engine consumes. Derived values (total duration, effective name) delegate to
/// the single-source calculators in `ProRoundsFoundationUtilities` (guide §6.5).
public struct Configuration: Sendable, Equatable, Hashable, Identifiable {
    /// Stable identity for persistence (save/update/delete by id). Defaults to a fresh value so
    /// in-memory construction (the engine and its tests) is unaffected.
    public let id: UUID
    public let workoutType: WorkoutType
    public let rounds: Int
    public let roundDuration: Duration
    public let restDuration: Duration
    public let prepDuration: Duration
    /// Seconds before each round ends that the warning cue plays. Zero means no warning.
    public let warningLead: Duration
    /// A user-supplied name; when nil/blank the effective name is auto-generated.
    public let customName: String?
    /// How much the coach says during this workout; nil means coaching is off.
    ///
    /// Deliberately not part of `WorkoutType`, and deliberately not part of the workout's
    /// arithmetic — a coached and an uncoached 12×3:00 have the same total and the same auto-name.
    public let coachingLevel: CoachingLevel?

    public init(
        id: UUID = UUID(),
        workoutType: WorkoutType,
        rounds: Int,
        roundDuration: Duration,
        restDuration: Duration,
        prepDuration: Duration,
        warningLead: Duration,
        customName: String? = nil,
        coachingLevel: CoachingLevel? = nil
    ) {
        self.id = id
        self.workoutType = workoutType
        self.rounds = rounds
        self.roundDuration = roundDuration
        self.restDuration = restDuration
        self.prepDuration = prepDuration
        self.warningLead = warningLead
        self.customName = customName
        self.coachingLevel = coachingLevel
    }

    /// Total workout time: round×N + rest×(N−1) — rounds + rest, prep excluded (it is a lead-in).
    public var totalDuration: Duration {
        WorkoutMath.totalDuration(
            round: roundDuration,
            rest: restDuration,
            rounds: rounds
        )
    }

    /// The custom name when present and non-blank, otherwise the auto-generated name.
    public var effectiveName: String {
        if let customName, !customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return customName
        }
        return WorkoutMath.autoName(
            workoutTypeName: workoutType.displayName,
            rounds: rounds,
            round: roundDuration,
            rest: restDuration
        )
    }
}

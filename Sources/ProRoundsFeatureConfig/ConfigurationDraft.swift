import Foundation
import ProRoundsDataConfig
import ProRoundsFoundationUtilities

/// The editor's mutable working copy. Durations are held as whole-second `Int`s for easy stepper
/// editing; derived values use the single-source calculators (guide §6.5).
struct ConfigurationDraft: Equatable {
    /// Clearing coaching on a switch to an unscripted type is deliberate: the alternatives are
    /// saving an invalid configuration or blocking the type change, both worse. It happens before
    /// save, so cancelling the edit still discards it.
    var workoutType: WorkoutType = .heavyBag {
        didSet {
            if !workoutType.supportsCoaching { coachingLevel = nil }
        }
    }
    var rounds: Int = 12
    var roundSeconds: Int = 180
    var restSeconds: Int = 60
    var prepSeconds: Int = 20
    var warningLeadSeconds: Int = 10
    var name: String = ""
    /// nil means coaching is off. Only settable for workout types with an authored script.
    var coachingLevel: CoachingLevel?

    init() {}

    init(_ config: Configuration) {
        workoutType = config.workoutType
        rounds = config.rounds
        roundSeconds = Int(config.roundDuration.components.seconds)
        restSeconds = Int(config.restDuration.components.seconds)
        prepSeconds = Int(config.prepDuration.components.seconds)
        warningLeadSeconds = Int(config.warningLead.components.seconds)
        name = config.customName ?? ""
        coachingLevel = config.coachingLevel
    }

    /// The editor shows a Coaching section only where a script exists, rather than a disabled
    /// control. Reads the same `supportsCoaching` source the validator does, so the rule and the UI
    /// cannot disagree about what is offerable.
    var showsCoachingSection: Bool { workoutType.supportsCoaching }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var total: Duration {
        WorkoutMath.totalDuration(
            round: .seconds(roundSeconds), rest: .seconds(restSeconds), rounds: rounds
        )
    }

    /// The live auto-generated name for the current fields (shown as the name field's placeholder).
    var autoName: String {
        WorkoutMath.autoName(workoutTypeName: workoutType.displayName, rounds: rounds,
                             round: .seconds(roundSeconds), rest: .seconds(restSeconds))
    }

    /// The custom name when non-blank, otherwise the live auto-generated name.
    var effectiveName: String {
        trimmedName.isEmpty ? autoName : trimmedName
    }

    func build(id: UUID) -> Configuration {
        Configuration(
            id: id, workoutType: workoutType, rounds: rounds,
            roundDuration: .seconds(roundSeconds), restDuration: .seconds(restSeconds),
            prepDuration: .seconds(prepSeconds), warningLead: .seconds(warningLeadSeconds),
            customName: trimmedName.isEmpty ? nil : trimmedName,
            coachingLevel: coachingLevel
        )
    }
}

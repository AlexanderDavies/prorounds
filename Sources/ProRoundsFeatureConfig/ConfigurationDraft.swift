import Foundation
import ProRoundsDataConfig
import ProRoundsFoundationUtilities

/// The editor's mutable working copy. Durations are held as whole-second `Int`s for easy stepper
/// editing; derived values use the single-source calculators (guide §6.5).
struct ConfigurationDraft: Equatable {
    var workoutType: WorkoutType = .heavyBag
    var rounds: Int = 12
    var roundSeconds: Int = 180
    var restSeconds: Int = 60
    var prepSeconds: Int = 20
    var warningLeadSeconds: Int = 10
    var name: String = ""

    init() {}

    init(_ config: Configuration) {
        workoutType = config.workoutType
        rounds = config.rounds
        roundSeconds = Int(config.roundDuration.components.seconds)
        restSeconds = Int(config.restDuration.components.seconds)
        prepSeconds = Int(config.prepDuration.components.seconds)
        warningLeadSeconds = Int(config.warningLead.components.seconds)
        name = config.customName ?? ""
    }

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
            customName: trimmedName.isEmpty ? nil : trimmedName
        )
    }
}

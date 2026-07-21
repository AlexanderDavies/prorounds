import Foundation
import ProRoundsFoundationUtilities

/// The single translation point between the SwiftData entity and the domain value type, so
/// reference-type entities never leak above the repository (guide §6.3). Durations map to whole
/// seconds via `Duration.components.seconds`.
enum ConfigurationMapper {
    static func seconds(_ duration: Duration) -> Int { Int(duration.components.seconds) }

    static func toDomain(_ entity: ConfigurationEntity) -> Configuration {
        Configuration(
            id: entity.id,
            workoutType: WorkoutType(rawValue: entity.workoutTypeRaw) ?? .shadowBoxing,
            rounds: entity.rounds,
            roundDuration: .seconds(entity.roundSeconds),
            restDuration: .seconds(entity.restSeconds),
            prepDuration: .seconds(entity.prepSeconds),
            warningLead: .seconds(entity.warningLeadSeconds),
            customName: entity.customName.isEmpty ? nil : entity.customName
        )
    }

    static func makeEntity(from config: Configuration, now: Date) -> ConfigurationEntity {
        ConfigurationEntity(
            id: config.id,
            workoutTypeRaw: config.workoutType.rawValue,
            rounds: config.rounds,
            roundSeconds: seconds(config.roundDuration),
            restSeconds: seconds(config.restDuration),
            prepSeconds: seconds(config.prepDuration),
            warningLeadSeconds: seconds(config.warningLead),
            customName: config.customName ?? "",
            createdAt: now,
            updatedAt: now
        )
    }

    /// Applies domain fields onto an existing entity (an in-place update), bumping `updatedAt`.
    static func apply(_ config: Configuration, to entity: ConfigurationEntity, now: Date) {
        entity.workoutTypeRaw = config.workoutType.rawValue
        entity.rounds = config.rounds
        entity.roundSeconds = seconds(config.roundDuration)
        entity.restSeconds = seconds(config.restDuration)
        entity.prepSeconds = seconds(config.prepDuration)
        entity.warningLeadSeconds = seconds(config.warningLead)
        entity.customName = config.customName ?? ""
        entity.updatedAt = now
    }
}

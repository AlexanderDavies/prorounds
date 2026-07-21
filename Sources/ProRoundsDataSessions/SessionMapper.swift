import Foundation
import ProRoundsFoundationUtilities

/// The single translation point between the SwiftData entity and the `Session` value type
/// (guide §6.3). Durations map to whole seconds.
enum SessionMapper {
    static func seconds(_ duration: Duration) -> Int { Int(duration.components.seconds) }

    static func toDomain(_ entity: SessionEntity) -> Session {
        Session(
            id: entity.id,
            date: entity.date,
            workoutType: WorkoutType(rawValue: entity.workoutTypeRaw) ?? .shadowBoxing,
            configurationName: entity.configurationName,
            rounds: entity.rounds,
            roundDuration: .seconds(entity.roundSeconds),
            restDuration: .seconds(entity.restSeconds),
            prepDuration: .seconds(entity.prepSeconds),
            roundsCompleted: entity.roundsCompleted,
            totalDuration: .seconds(entity.totalSeconds)
        )
    }

    static func makeEntity(from session: Session) -> SessionEntity {
        SessionEntity(
            id: session.id,
            date: session.date,
            workoutTypeRaw: session.workoutType.rawValue,
            configurationName: session.configurationName,
            rounds: session.rounds,
            roundSeconds: seconds(session.roundDuration),
            restSeconds: seconds(session.restDuration),
            prepSeconds: seconds(session.prepDuration),
            roundsCompleted: session.roundsCompleted,
            totalSeconds: seconds(session.totalDuration)
        )
    }
}

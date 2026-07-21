import Foundation
import ProRoundsDataConfig
import ProRoundsDataSessions

extension Session {
    /// Builds a session for a workout completed under `configuration` (a natural finish completes
    /// every round).
    init(completed configuration: Configuration, at date: Date) {
        self.init(
            date: date,
            workoutType: configuration.workoutType,
            configurationName: configuration.effectiveName,
            rounds: configuration.rounds,
            roundDuration: configuration.roundDuration,
            restDuration: configuration.restDuration,
            prepDuration: configuration.prepDuration,
            roundsCompleted: configuration.rounds,
            totalDuration: configuration.totalDuration
        )
    }
}

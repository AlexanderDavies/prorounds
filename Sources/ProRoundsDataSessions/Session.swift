import Foundation
import ProRoundsFoundationUtilities

/// A completed workout recorded for history and the performance chart (app prompt §3). A value type;
/// the `Configuration → Session` mapping lives in the feature layer that knows both types, so this
/// module needs no dependency on the config data layer.
public struct Session: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let date: Date
    public let workoutType: WorkoutType
    public let configurationName: String
    public let rounds: Int
    public let roundDuration: Duration
    public let restDuration: Duration
    public let prepDuration: Duration
    public let roundsCompleted: Int
    public let totalDuration: Duration

    public init(
        id: UUID = UUID(),
        date: Date,
        workoutType: WorkoutType,
        configurationName: String,
        rounds: Int,
        roundDuration: Duration,
        restDuration: Duration,
        prepDuration: Duration,
        roundsCompleted: Int,
        totalDuration: Duration
    ) {
        self.id = id
        self.date = date
        self.workoutType = workoutType
        self.configurationName = configurationName
        self.rounds = rounds
        self.roundDuration = roundDuration
        self.restDuration = restDuration
        self.prepDuration = prepDuration
        self.roundsCompleted = roundsCompleted
        self.totalDuration = totalDuration
    }

    /// Time under work — sum of the completed rounds' round time (rest and prep excluded). The metric
    /// the performance chart plots (DESIGN §7.4).
    public var activeDuration: Duration { roundDuration * roundsCompleted }
}

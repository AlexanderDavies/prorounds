import Foundation

/// The user-selectable round-end warning sounds (the three options from the spec).
public enum WarningSound: String, CaseIterable, Codable, Sendable, Equatable {
    case woodenClap
    case electronicHorn
    case buzzer
}

/// A moment the timer engine signals. The engine decides *when* each cue fires; the player decides
/// *how it sounds*. Equatable/Sendable so tests can assert the exact cue sequence of a workout.
public enum AudioCue: Equatable, Sendable {
    case roundStart
    case roundEndWarning(WarningSound)
    case roundEnd
    case restStart
    case workoutComplete
}

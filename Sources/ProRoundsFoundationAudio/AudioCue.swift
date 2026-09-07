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
    /// A spoken clip at a resolved file location.
    ///
    /// A location rather than a phrase id on purpose: an id would force this module to depend on the
    /// coaching module to resolve it, pushing the dependency the wrong way down the layering. By the
    /// time a cue exists the clip has already been chosen, so the player stays a dumb player.
    case spoken(URL)
}

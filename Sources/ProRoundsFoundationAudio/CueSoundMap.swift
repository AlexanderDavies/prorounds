import Foundation

/// A bundled sound asset. Raw value is the resource file name (without extension).
public enum SoundAsset: String, CaseIterable, Sendable {
    case bell
    case woodenClap = "wooden_clap"
    case electronicHorn = "electronic_horn"
    case buzzer
    case complete

    public var fileExtension: String { "wav" }
}

/// The pure mapping from a cue (and warning sound) to a sound asset — unit-tested independently of
/// audio hardware so the concrete player stays a thin platform-edge adapter (guide §8.1, §14.4).
public enum CueSoundMap {
    /// The bundled asset for a cue, or nil when the cue names its own file instead.
    ///
    /// Optional since spoken cues arrived: a coaching call carries a clip location rather than one
    /// of the five bundled sounds, so there is nothing here to map it to.
    public static func sound(for cue: AudioCue) -> SoundAsset? {
        switch cue {
        case .roundStart, .roundEnd, .restStart:
            return .bell
        case .roundEndWarning(let warning):
            return sound(for: warning)
        case .workoutComplete:
            return .complete
        case .spoken:
            return nil
        }
    }

    public static func sound(for warning: WarningSound) -> SoundAsset {
        switch warning {
        case .woodenClap: return .woodenClap
        case .electronicHorn: return .electronicHorn
        case .buzzer: return .buzzer
        }
    }
}

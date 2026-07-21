import Foundation

/// The audio seam. The engine emits cues through this protocol so it never imports an audio
/// framework and tests can assert on cues without touching hardware. The concrete
/// `AVFoundation`-backed player is added in a later change.
public protocol AudioCuePlayer: Sendable {
    /// Preload buffers so the first cue isn't late.
    func prepare() async
    /// Emit a cue.
    func play(_ cue: AudioCue) async
}

/// A test double recording the cues it was asked to play, in order.
public actor SpyAudioCuePlayer: AudioCuePlayer {
    public private(set) var played: [AudioCue] = []
    public private(set) var prepareCallCount = 0

    public init() {}

    public func prepare() async { prepareCallCount += 1 }

    public func play(_ cue: AudioCue) async { played.append(cue) }
}

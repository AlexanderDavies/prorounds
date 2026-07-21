import Foundation
import AVFoundation

/// The concrete `AudioCuePlayer` — the one place audio frameworks are imported (guide §8.1). Preloads
/// the bundled sounds and plays the mapped sound for each cue with low latency. An actor so its
/// non-`Sendable` `AVAudioPlayer`s stay isolated.
///
/// Session/background behaviour (iOS): a `.playback` session with `.duckOthers` (music dips for a
/// cue, cues sound with the ringer silent); combined with the app's `audio` background mode this
/// keeps cues firing with the screen locked. On non-iOS hosts the session calls are no-ops so the
/// module still builds for the macOS test loop.
public actor AVAudioCuePlayer: AudioCuePlayer {
    private var players: [SoundAsset: AVAudioPlayer] = [:]

    public init() {}

    public func prepare() async {
        configureSession()
        for asset in SoundAsset.allCases where players[asset] == nil {
            guard let url = Bundle.module.url(forResource: asset.rawValue, withExtension: asset.fileExtension),
                  let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.prepareToPlay()
            players[asset] = player
        }
    }

    public func play(_ cue: AudioCue) async {
        let player = players[CueSoundMap.sound(for: cue)]
        player?.currentTime = 0
        player?.play()
    }

    /// Number of successfully preloaded sounds (for tests).
    var preparedCount: Int { players.count }

    private func configureSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.duckOthers])
        try? session.setActive(true)
        #endif
    }
}

import Testing
@testable import ProRoundsFoundationAudio

@Suite("CueSoundMap")
struct CueSoundMapTests {
    @Test("Warning cue selects the configured warning sound")
    func warningSelectsSound() {
        #expect(CueSoundMap.sound(for: .roundEndWarning(.buzzer)) == .buzzer)
        #expect(CueSoundMap.sound(for: .roundEndWarning(.electronicHorn)) == .electronicHorn)
        #expect(CueSoundMap.sound(for: .roundEndWarning(.woodenClap)) == .woodenClap)
    }

    @Test("Bell and complete map to their sounds")
    func bellAndComplete() {
        #expect(CueSoundMap.sound(for: .roundStart) == .bell)
        #expect(CueSoundMap.sound(for: .roundEnd) == .bell)
        #expect(CueSoundMap.sound(for: .restStart) == .bell)
        #expect(CueSoundMap.sound(for: .workoutComplete) == .complete)
    }
}

@Suite("AVAudioCuePlayer")
struct AVAudioCuePlayerTests {
    @Test("Prepare preloads every bundled sound and play does not crash")
    func preparesAndPlays() async {
        let player = AVAudioCuePlayer()
        await player.prepare()
        #expect(await player.preparedCount == SoundAsset.allCases.count)
        await player.play(.roundStart)
        await player.play(.roundEndWarning(.buzzer))
        await player.play(.workoutComplete)
    }
}

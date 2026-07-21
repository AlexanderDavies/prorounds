import Testing
@testable import ProRoundsFoundationAudio

@Suite("Audio cues")
struct AudioCueTests {
    @Test("Three warning sounds are available")
    func warningSounds() {
        #expect(WarningSound.allCases == [.woodenClap, .electronicHorn, .buzzer])
    }

    @Test("Cue equality distinguishes the warning sound")
    func cueEquality() {
        #expect(AudioCue.roundStart == AudioCue.roundStart)
        #expect(AudioCue.roundEndWarning(.buzzer) == AudioCue.roundEndWarning(.buzzer))
        #expect(AudioCue.roundEndWarning(.buzzer) != AudioCue.roundEndWarning(.woodenClap))
        #expect(AudioCue.roundEnd != AudioCue.restStart)
    }

    @Test("SpyAudioCuePlayer records play order and prepare calls")
    func spyRecordsOrder() async {
        let spy = SpyAudioCuePlayer()
        await spy.prepare()
        await spy.play(.roundStart)
        await spy.play(.roundEndWarning(.electronicHorn))
        await spy.play(.workoutComplete)
        #expect(await spy.prepareCallCount == 1)
        #expect(await spy.played == [.roundStart, .roundEndWarning(.electronicHorn), .workoutComplete])
    }
}

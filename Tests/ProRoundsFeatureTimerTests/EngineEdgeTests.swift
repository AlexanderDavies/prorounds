import Testing
import Foundation
@testable import ProRoundsFeatureTimer
import ProRoundsDataConfig
import ProRoundsFoundationAudio
import ProRoundsFoundationTiming

@MainActor
@Suite("RoundTimerEngine — edges")
struct EngineEdgeTests {
    @Test("togglePause is a no-op before start, then toggles pause/resume")
    func togglePausePublicPath() {
        let fake = FakeTimeSource()
        let engine = RoundTimerEngine(
            configuration: Configuration(
                workoutType: .heavyBag, rounds: 1, roundDuration: .seconds(30),
                restDuration: .zero, prepDuration: .zero, warningLead: .zero
            ),
            timeSource: fake,
            player: SpyAudioCuePlayer()
        )

        engine.togglePause() // not started → ignored
        #expect(!engine.snapshot.isPaused)

        _ = engine.beginTimeline(at: fake.now)
        engine.togglePause() // pause
        #expect(engine.snapshot.isPaused)
        engine.togglePause() // resume
        #expect(!engine.snapshot.isPaused)
    }

    @Test("A zero-round configuration finishes immediately")
    func zeroRoundsFinishesImmediately() {
        let engine = EngineFixture.make(prep: 0, round: 10, rest: 0, rounds: 0, lead: 0)
        let cues = engine.beginTimeline(at: ContinuousClock().now)
        #expect(engine.snapshot.phase == .finished)
        #expect(cues == [.workoutComplete])
    }
}

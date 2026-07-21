import Testing
import Foundation
@testable import ProRoundsFeatureTimer
import ProRoundsDataConfig
import ProRoundsFoundationAudio
import ProRoundsFoundationTiming

@MainActor
@Suite("RoundTimerEngine — async tick driver")
struct EngineDriverTests {
    @Test("Driving the engine through its tick loop plays cues to the player, in order")
    func asyncDriverPlaysCuesInOrder() async {
        let fake = FakeTimeSource()
        let spy = SpyAudioCuePlayer()
        let config = Configuration(
            workoutType: .heavyBag,
            rounds: 2,
            roundDuration: .seconds(3),
            restDuration: .seconds(1),
            prepDuration: .seconds(0),
            warningLead: .seconds(1)
        )
        let engine = RoundTimerEngine(
            configuration: config,
            timeSource: fake,
            player: spy,
            warningSound: .buzzer
        )

        engine.start()
        // Emit one tick per second across the whole workout (3 + 1 + 3 = 7s); overshoot slightly.
        for _ in 0..<8 { fake.advanceAndTick(by: .seconds(1)) }

        // Let the MainActor tick loop drain the buffered ticks and play their cues.
        var iterations = 0
        while await spy.played.count < 8, iterations < 100_000 {
            await Task.yield()
            iterations += 1
        }

        #expect(engine.snapshot.phase == .finished)
        #expect(await spy.played == [
            .roundStart, .roundEndWarning(.buzzer), .roundEnd, .restStart,
            .roundStart, .roundEndWarning(.buzzer), .roundEnd, .workoutComplete
        ])
        #expect(await spy.prepareCallCount == 1)

        engine.reset() // cancels the tick loop
    }
}

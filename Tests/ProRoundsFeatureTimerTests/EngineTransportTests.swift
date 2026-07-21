import Testing
import Foundation
@testable import ProRoundsFeatureTimer

@MainActor
@Suite("RoundTimerEngine — transport")
struct EngineTransportTests {
    @Test("No time accrues while paused; resume preserves remaining")
    func pausePreservesRemaining() {
        let engine = EngineFixture.make(prep: 0, round: 30, rest: 0, rounds: 1, lead: 0)
        let t0 = ContinuousClock().now
        _ = engine.beginTimeline(at: t0)

        _ = engine.pause(at: t0)
        #expect(engine.snapshot.isPaused)
        #expect(engine.snapshot.remaining == .seconds(30))

        // A tick arriving while paused is a no-op and emits no cue.
        let whilePaused = engine.processTick(at: t0.advanced(by: .seconds(100)))
        #expect(whilePaused.isEmpty)
        #expect(engine.snapshot.phase == .round(index: 1))
        #expect(engine.snapshot.remaining == .seconds(30))

        // Resume 10s later: still 30s remaining, completing 30s after resume.
        _ = engine.resume(at: t0.advanced(by: .seconds(10)))
        #expect(!engine.snapshot.isPaused)
        #expect(engine.snapshot.remaining == .seconds(30))

        _ = engine.processTick(at: t0.advanced(by: .seconds(39)))
        #expect(engine.snapshot.phase == .round(index: 1)) // 1s left

        _ = engine.processTick(at: t0.advanced(by: .seconds(40)))
        #expect(engine.snapshot.phase == .finished)
    }

    @Test("Reset returns to the pre-start state; restart runs the full sequence again")
    func resetThenRestart() {
        let engine = EngineFixture.make(prep: 5, round: 10, rest: 3, rounds: 2, lead: 0)
        let t0 = ContinuousClock().now
        _ = engine.beginTimeline(at: t0)
        _ = engine.processTick(at: t0.advanced(by: .seconds(7))) // partway into round 1

        engine.reset()
        #expect(engine.snapshot.phase == .preparing)      // first phase (prep > 0)
        #expect(engine.snapshot.remaining == .seconds(5)) // full prep
        #expect(engine.snapshot.elapsedTotal == .zero)
        #expect(!engine.snapshot.isPaused)

        // Restart and run to completion again.
        let t1 = t0.advanced(by: .seconds(1000))
        let (phases, _) = engine.driveWholeWorkout(from: t1, totalSeconds: 45)
        #expect(phases.first == .preparing)
        #expect(phases.last == .finished)
    }

    @Test("The snapshot carries a run-state: not-started before start and after reset")
    func snapshotReportsRunState() {
        let engine = EngineFixture.make(prep: 5, round: 10, rest: 3, rounds: 2, lead: 0)
        // Before start: idle.
        #expect(!engine.snapshot.started)

        let t0 = ContinuousClock().now
        _ = engine.beginTimeline(at: t0)
        #expect(engine.snapshot.started)

        _ = engine.processTick(at: t0.advanced(by: .seconds(7)))
        #expect(engine.snapshot.started) // still started mid-workout

        engine.reset()
        #expect(!engine.snapshot.started) // idle again after reset
    }
}

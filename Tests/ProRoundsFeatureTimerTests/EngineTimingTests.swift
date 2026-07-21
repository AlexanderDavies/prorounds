import Testing
import Foundation
@testable import ProRoundsFeatureTimer
import ProRoundsFoundationAudio

@MainActor
@Suite("RoundTimerEngine — deadline timing")
struct EngineTimingTests {
    @Test("Irregular, coarse ticks still end the phase exactly at its deadline")
    func coarseTicksHonourDeadline() {
        let engine = EngineFixture.make(prep: 0, round: 60, rest: 0, rounds: 1, lead: 0)
        let t0 = ContinuousClock().now
        _ = engine.beginTimeline(at: t0)

        _ = engine.processTick(at: t0.advanced(by: .seconds(1)))
        #expect(engine.snapshot.remaining == .seconds(59))

        _ = engine.processTick(at: t0.advanced(by: .seconds(41)))
        #expect(engine.snapshot.remaining == .seconds(19))
        #expect(engine.snapshot.remaining >= .zero)

        // Overshoot the deadline — the round ends, remaining clamps to zero, not negative.
        _ = engine.processTick(at: t0.advanced(by: .seconds(66)))
        #expect(engine.snapshot.phase == .finished)
        #expect(engine.snapshot.remaining == .zero)
    }

    @Test("A single tick crossing several deadlines transitions through exactly the crossed phases")
    func longGapCrossesMultipleDeadlines() {
        let engine = EngineFixture.make(prep: 0, round: 10, rest: 3, rounds: 3, lead: 0)
        let t0 = ContinuousClock().now
        var cues = engine.beginTimeline(at: t0)

        // Jump past every deadline in one tick: 10+3+10+3+10 = 36s.
        cues += engine.processTick(at: t0.advanced(by: .seconds(36)))

        #expect(engine.snapshot.phase == .finished)
        #expect(cues == [
            .roundStart,                        // begin
            .roundEnd, .restStart,              // round 1 → rest
            .roundStart, .roundEnd, .restStart, // round 2 → rest
            .roundStart, .roundEnd,             // round 3
            .workoutComplete
        ])
    }

    @Test("Remaining and elapsed are consistent within a phase")
    func snapshotConsistency() {
        let engine = EngineFixture.make(prep: 5, round: 10, rest: 3, rounds: 2, lead: 0)
        let t0 = ContinuousClock().now
        _ = engine.beginTimeline(at: t0)

        // 7s in: prep (5s) done, 2s into round 1.
        _ = engine.processTick(at: t0.advanced(by: .seconds(7)))
        let snap = engine.snapshot
        #expect(snap.phase == .round(index: 1))
        #expect(snap.elapsedInPhase == .seconds(2))
        #expect(snap.remaining == .seconds(8))
        #expect(snap.remaining + snap.elapsedInPhase == .seconds(10)) // phase duration
        #expect(snap.elapsedTotal == .seconds(2))                    // 2 in round; prep (5s) excluded
    }

    @Test("Prep is a lead-in: it does not advance the workout total")
    func prepDoesNotAdvanceTotal() {
        let engine = EngineFixture.make(prep: 5, round: 10, rest: 0, rounds: 2, lead: 0)
        let t0 = ContinuousClock().now
        _ = engine.beginTimeline(at: t0)

        // 3s into prep: total not started (elapsedTotal 0), total-remaining = full rounds+rest (20s).
        _ = engine.processTick(at: t0.advanced(by: .seconds(3)))
        #expect(engine.snapshot.phase == .preparing)
        #expect(engine.snapshot.elapsedTotal == .zero)
        #expect(engine.snapshot.totalDuration == .seconds(2 * 10)) // 2 rounds × 10s, no rest, prep excluded
        #expect(engine.snapshot.totalDuration - engine.snapshot.elapsedTotal == .seconds(20))

        // 3s into round 1 (prep 5 + 3): the clock has started — elapsedTotal = 3.
        _ = engine.processTick(at: t0.advanced(by: .seconds(8)))
        #expect(engine.snapshot.phase == .round(index: 1))
        #expect(engine.snapshot.elapsedTotal == .seconds(3))
    }
}

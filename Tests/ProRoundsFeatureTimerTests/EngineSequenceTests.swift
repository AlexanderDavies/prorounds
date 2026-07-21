import Testing
import Foundation
@testable import ProRoundsFeatureTimer
import ProRoundsFoundationAudio

@MainActor
@Suite("RoundTimerEngine — sequence")
struct EngineSequenceTests {
    @Test("Three-round workout produces the exact phase order with no rest after the final round")
    func exactPhaseOrder() {
        let engine = EngineFixture.make(prep: 5, round: 10, rest: 3, rounds: 3, lead: 0)
        let t0 = ContinuousClock().now
        let (phases, _) = engine.driveWholeWorkout(from: t0, totalSeconds: 45)

        #expect(phases == [
            .preparing,
            .round(index: 1),
            .resting(afterRound: 1),
            .round(index: 2),
            .resting(afterRound: 2),
            .round(index: 3),
            .finished
        ])
    }

    @Test("Round indices are 1-based and never exceed the count")
    func roundIndicesBounded() {
        let engine = EngineFixture.make(prep: 0, round: 4, rest: 2, rounds: 3, lead: 0)
        let t0 = ContinuousClock().now
        let (phases, _) = engine.driveWholeWorkout(from: t0, totalSeconds: 30)
        for phase in phases {
            if case .round(let index) = phase { #expect(index >= 1 && index <= 3) }
            if case .resting(let after) = phase { #expect(after >= 1 && after <= 2) }
        }
    }

    @Test("Zero prep starts at round 1, not a zero-length preparing phase")
    func zeroPrepStartsAtRoundOne() {
        let engine = EngineFixture.make(prep: 0, round: 10, rest: 3, rounds: 2, lead: 0)
        let t0 = ContinuousClock().now
        let initialCues = engine.beginTimeline(at: t0)
        #expect(engine.snapshot.phase == .round(index: 1))
        #expect(initialCues == [.roundStart])
    }

    @Test("Finished is terminal: complete fires once and no further transitions occur")
    func finishedIsTerminal() {
        let engine = EngineFixture.make(prep: 0, round: 5, rest: 0, rounds: 1, lead: 0)
        let t0 = ContinuousClock().now
        let (_, cues) = engine.driveWholeWorkout(from: t0, totalSeconds: 6)
        #expect(engine.snapshot.phase == .finished)
        #expect(cues.filter { $0 == .workoutComplete }.count == 1)

        // Advancing further yields nothing.
        let extra = engine.processTick(at: t0.advanced(by: .seconds(100)))
        #expect(extra.isEmpty)
        #expect(engine.snapshot.phase == .finished)
    }
}

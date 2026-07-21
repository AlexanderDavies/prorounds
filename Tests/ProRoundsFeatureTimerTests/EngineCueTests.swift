import Testing
import Foundation
@testable import ProRoundsFeatureTimer
import ProRoundsFoundationAudio

@MainActor
@Suite("RoundTimerEngine — cues")
struct EngineCueTests {
    @Test("Warning fires once per round at deadline − lead")
    func warningAtLead() {
        let engine = EngineFixture.make(prep: 0, round: 60, rest: 0, rounds: 1, lead: 10)
        let t0 = ContinuousClock().now
        _ = engine.beginTimeline(at: t0)

        #expect(engine.processTick(at: t0.advanced(by: .seconds(49))).isEmpty)     // before lead
        #expect(engine.processTick(at: t0.advanced(by: .seconds(50))) == [.roundEndWarning(.buzzer)])
        #expect(engine.processTick(at: t0.advanced(by: .seconds(51))).isEmpty)     // no duplicate
    }

    @Test("Zero lead suppresses the warning entirely")
    func zeroLeadNoWarning() {
        let engine = EngineFixture.make(prep: 0, round: 10, rest: 0, rounds: 2, lead: 0)
        let t0 = ContinuousClock().now
        let (_, cues) = engine.driveWholeWorkout(from: t0, totalSeconds: 25)
        #expect(!cues.contains { if case .roundEndWarning = $0 { return true } else { return false } })
    }

    @Test("Warning lead ≥ round duration clamps the warning to the round start")
    func leadClampedToRoundStart() {
        let engine = EngineFixture.make(prep: 0, round: 10, rest: 0, rounds: 1, lead: 15)
        let t0 = ContinuousClock().now
        _ = engine.beginTimeline(at: t0)
        // First tick into the round already fires the (clamped) warning.
        #expect(engine.processTick(at: t0.advanced(by: .seconds(1))) == [.roundEndWarning(.buzzer)])
    }

    @Test("Two-round workout emits cues in the exact spec order")
    func fullCueOrder() {
        let engine = EngineFixture.make(prep: 5, round: 20, rest: 3, rounds: 2, lead: 5)
        let t0 = ContinuousClock().now
        let (_, cues) = engine.driveWholeWorkout(from: t0, totalSeconds: 50)

        #expect(cues == [
            .roundStart, .roundEndWarning(.buzzer), .roundEnd, .restStart,
            .roundStart, .roundEndWarning(.buzzer), .roundEnd, .workoutComplete
        ])
    }
}

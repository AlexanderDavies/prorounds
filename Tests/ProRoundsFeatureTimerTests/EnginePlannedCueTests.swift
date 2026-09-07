import Testing
import Foundation
@testable import ProRoundsFeatureTimer
import ProRoundsDataConfig
import ProRoundsFoundationAudio
import ProRoundsFoundationTiming

@MainActor
@Suite("Engine — planned cues")
struct EnginePlannedCueTests {
    private let clipA = URL(fileURLWithPath: "/tmp/a.m4a")
    private let clipB = URL(fileURLWithPath: "/tmp/b.m4a")
    private let clipC = URL(fileURLWithPath: "/tmp/c.m4a")

    private func engine(
        plan: [PlannedCue],
        prep: Int = 0, round: Int = 60, rest: Int = 30, rounds: Int = 2, lead: Int = 0
    ) -> RoundTimerEngine {
        let config = Configuration(
            workoutType: .heavyBag, rounds: rounds,
            roundDuration: .seconds(round), restDuration: .seconds(rest),
            prepDuration: .seconds(prep), warningLead: .seconds(lead))
        return RoundTimerEngine(
            configuration: config, timeSource: FakeTimeSource(), player: SpyAudioCuePlayer(),
            warningSound: .buzzer, cuePlanner: FixedRoundCuePlanner(cues: plan))
    }

    private func planned(_ seconds: Int, _ clip: URL) -> PlannedCue {
        PlannedCue(offset: .seconds(seconds), cue: .spoken(clip), tickerPrimary: "call")
    }

    /// Collects cues by ticking one second at a time, recording the second each cue arrived at.
    private func run(_ engine: RoundTimerEngine, seconds: Int) -> [(second: Int, cue: AudioCue)] {
        var out: [(Int, AudioCue)] = []
        let start = Instant.now
        for cue in engine.beginTimeline(at: start) { out.append((0, cue)) }
        for second in 1...seconds {
            for cue in engine.processTick(at: start.advanced(by: .seconds(second))) {
                out.append((second, cue))
            }
        }
        return out
    }

    @Test("a planned cue fires exactly once, at its offset")
    func firesAtItsOffset() {
        let fired = run(engine(plan: [planned(30, clipA)]), seconds: 60)
            .filter { $0.cue == .spoken(clipA) }
        #expect(fired.count == 1)
        #expect(fired.first?.second == 30)
    }

    @Test("cues fire in ascending offset order")
    func firesInOrder() {
        let plan = [planned(45, clipC), planned(10, clipA), planned(25, clipB)]
        let spoken = run(engine(plan: plan), seconds: 60)
            .compactMap { entry -> URL? in
                if case .spoken(let url) = entry.cue { return url }
                return nil
            }
        #expect(spoken == [clipA, clipB, clipC])
    }

    /// A backgrounded app resumes with a large jump. Every crossed cue must fire, in order, none
    /// skipped and none doubled — the same guarantee the phase loop already gives.
    @Test("a clock jump past several offsets fires all of them, once each, in order")
    func clockJumpFiresAll() {
        let engine = engine(plan: [planned(10, clipA), planned(20, clipB), planned(30, clipC)])
        let start = Instant.now
        _ = engine.beginTimeline(at: start)
        let cues = engine.processTick(at: start.advanced(by: .seconds(40)))
        let spoken = cues.compactMap { cue -> URL? in
            if case .spoken(let url) = cue { return url }
            return nil
        }
        #expect(spoken == [clipA, clipB, clipC])
    }

    @Test("a cue is never emitted twice")
    func neverFiresTwice() {
        let engine = engine(plan: [planned(10, clipA)])
        let all = run(engine, seconds: 55)
        #expect(all.filter { $0.cue == .spoken(clipA) }.count == 1)
    }

    @Test("an offset beyond the round never fires, and the round still ends on time")
    func offsetBeyondRoundIsTruncated() {
        let result = run(engine(plan: [planned(90, clipA)]), seconds: 60)
        #expect(!result.contains { $0.cue == .spoken(clipA) })
        #expect(result.contains { $0.second == 60 && $0.cue == .roundEnd })
    }

    @Test("each round gets its own plan, and cues do not leak across the boundary")
    func cuesDoNotLeakAcrossRounds() {
        // 60s round, 30s rest, 2 rounds. Round 2 starts at 90s.
        let result = run(engine(plan: [planned(10, clipA)]), seconds: 150)
        let seconds = result.filter { $0.cue == .spoken(clipA) }.map(\.second)
        #expect(seconds == [10, 100], "expected one call per round, got \(seconds)")
    }

    @Test("no coaching cue fires during rest")
    func silentDuringRest() {
        let result = run(engine(plan: [planned(10, clipA)]), seconds: 150)
        for entry in result where entry.cue == .spoken(clipA) {
            #expect(entry.second < 60 || entry.second >= 90, "fired at \(entry.second), inside rest")
        }
    }

    /// The regression that matters most. Coaching must not move a phase boundary, change a round
    /// count, or delay the bell — so the non-coaching cues must land on identical instants whether
    /// a plan is present or not.
    @Test("a plan changes no phase transition and no existing cue")
    func planChangesNothingElse() {
        let withPlan = run(engine(plan: [planned(5, clipA), planned(25, clipB)],
                                  prep: 10, round: 60, rest: 30, rounds: 3, lead: 10), seconds: 300)
        let without = run(engine(plan: [], prep: 10, round: 60, rest: 30, rounds: 3, lead: 10),
                          seconds: 300)
        func nonCoaching(_ entries: [(second: Int, cue: AudioCue)]) -> [String] {
            entries.filter { if case .spoken = $0.cue { return false } else { return true } }
                .map { "\($0.second):\($0.cue)" }
        }
        #expect(nonCoaching(withPlan) == nonCoaching(without))
    }

    @Test("an empty plan behaves exactly as the feature-less engine")
    func emptyPlanIsInert() {
        let planned = run(engine(plan: []), seconds: 150).map { "\($0.second):\($0.cue)" }
        let bare = run(EngineFixture.make(prep: 0, round: 60, rest: 30, rounds: 2, lead: 0),
                       seconds: 150).map { "\($0.second):\($0.cue)" }
        #expect(planned == bare)
    }
}

@MainActor
@Suite("Engine — planned cues under transport")
struct EnginePlannedCueTransportTests {
    private let clip = URL(fileURLWithPath: "/tmp/x.m4a")

    private func engine(_ plan: [PlannedCue]) -> RoundTimerEngine {
        let config = Configuration(
            workoutType: .heavyBag, rounds: 2, roundDuration: .seconds(60),
            restDuration: .seconds(30), prepDuration: .zero, warningLead: .zero)
        return RoundTimerEngine(
            configuration: config, timeSource: FakeTimeSource(), player: SpyAudioCuePlayer(),
            warningSound: .buzzer, cuePlanner: FixedRoundCuePlanner(cues: plan))
    }

    private func planned(_ seconds: Int) -> PlannedCue {
        PlannedCue(offset: .seconds(seconds), cue: .spoken(clip), tickerPrimary: "call")
    }

    @Test("no cue fires while paused")
    func silentWhilePaused() {
        let engine = engine([planned(30)])
        let start = Instant.now
        _ = engine.beginTimeline(at: start)
        _ = engine.pause(at: start.advanced(by: .seconds(10)))
        // The clock runs past the offset while paused.
        let cues = engine.processTick(at: start.advanced(by: .seconds(40)))
        #expect(!cues.contains(.spoken(clip)))
    }

    /// The engine already recomputes deadlines on resume rather than trusting a paused counter, so
    /// a planned cue must ride the same recomputation — the offset is round-relative, and the pause
    /// does not count.
    @Test("a cue not yet reached still fires after a resume")
    func firesAfterResume() {
        let engine = engine([planned(30)])
        let start = Instant.now
        _ = engine.beginTimeline(at: start)
        _ = engine.pause(at: start.advanced(by: .seconds(10)))
        _ = engine.resume(at: start.advanced(by: .seconds(70)))   // 60s paused
        // 30s into the round is now 90s of wall time.
        let early = engine.processTick(at: start.advanced(by: .seconds(85)))
        #expect(!early.contains(.spoken(clip)), "fired before its round-relative offset")
        let onTime = engine.processTick(at: start.advanced(by: .seconds(95)))
        #expect(onTime.contains(.spoken(clip)))
    }

    @Test("reset discards the abandoned round's plan")
    func resetDiscardsThePlan() {
        let engine = engine([planned(30)])
        let start = Instant.now
        _ = engine.beginTimeline(at: start)
        engine.reset()
        let cues = engine.processTick(at: start.advanced(by: .seconds(40)))
        #expect(!cues.contains(.spoken(clip)))
    }

    @Test("restarting after a reset plans the round afresh")
    func restartReplansTheRound() {
        let engine = engine([planned(30)])
        let start = Instant.now
        _ = engine.beginTimeline(at: start)
        engine.reset()
        let restart = start.advanced(by: .seconds(100))
        _ = engine.beginTimeline(at: restart)
        let cues = engine.processTick(at: restart.advanced(by: .seconds(30)))
        #expect(cues.contains(.spoken(clip)))
    }
}

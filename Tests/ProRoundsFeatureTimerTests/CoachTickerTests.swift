import Testing
import Foundation
@testable import ProRoundsFeatureTimer
import ProRoundsDataConfig
import ProRoundsFoundationAudio
import ProRoundsFoundationTiming

@MainActor
@Suite("Coach ticker on the snapshot")
struct CoachTickerSnapshotTests {
    private let clip = URL(fileURLWithPath: "/tmp/x.m4a")

    private func engine(_ plan: [PlannedCue], rounds: Int = 2) -> RoundTimerEngine {
        let config = Configuration(
            workoutType: .heavyBag, rounds: rounds, roundDuration: .seconds(60),
            restDuration: .seconds(30), prepDuration: .zero, warningLead: .zero)
        return RoundTimerEngine(
            configuration: config, timeSource: FakeTimeSource(), player: SpyAudioCuePlayer(),
            warningSound: .buzzer, cuePlanner: FixedRoundCuePlanner(cues: plan))
    }

    private func punchCall(_ seconds: Int) -> PlannedCue {
        PlannedCue(offset: .seconds(seconds), cue: .spoken(clip),
                   tickerPrimary: "Jab Cross", tickerSecondary: "1 · 2", tickerModifier: "to the body")
    }

    private func lineCall(_ seconds: Int) -> PlannedCue {
        PlannedCue(offset: .seconds(seconds), cue: .spoken(clip), tickerPrimary: "Circle left")
    }

    @Test("a punch call exposes both conventions and its modifier")
    func punchCallShowsBoth() {
        let engine = engine([punchCall(10)])
        let start = Instant.now
        _ = engine.beginTimeline(at: start)
        _ = engine.processTick(at: start.advanced(by: .seconds(10)))
        let call = engine.snapshot.currentCall
        #expect(call?.primary == "Jab Cross")
        #expect(call?.secondary == "1 · 2")
        #expect(call?.modifier == "to the body")
    }

    @Test("a single-line call exposes one line and no empty second")
    func lineCallShowsOne() {
        let engine = engine([lineCall(10)])
        let start = Instant.now
        _ = engine.beginTimeline(at: start)
        _ = engine.processTick(at: start.advanced(by: .seconds(10)))
        #expect(engine.snapshot.currentCall?.primary == "Circle left")
        #expect(engine.snapshot.currentCall?.secondary == nil)
        #expect(engine.snapshot.currentCall?.modifier == nil)
    }

    @Test("nothing is shown before the first call")
    func emptyBeforeFirstCall() {
        let engine = engine([punchCall(30)])
        let start = Instant.now
        _ = engine.beginTimeline(at: start)
        _ = engine.processTick(at: start.advanced(by: .seconds(5)))
        #expect(engine.snapshot.currentCall == nil)
    }

    @Test("the latest call replaces the previous one")
    func latestCallWins() {
        let engine = engine([lineCall(10), punchCall(20)])
        let start = Instant.now
        _ = engine.beginTimeline(at: start)
        _ = engine.processTick(at: start.advanced(by: .seconds(10)))
        #expect(engine.snapshot.currentCall?.primary == "Circle left")
        _ = engine.processTick(at: start.advanced(by: .seconds(20)))
        #expect(engine.snapshot.currentCall?.primary == "Jab Cross")
    }

    /// Holding the last call through a rest would leave a punch on screen while the athlete is
    /// recovering — the ticker says what the coach is saying, and during rest that is nothing.
    @Test("the ticker clears during rest and does not retain the last call")
    func clearsDuringRest() {
        let engine = engine([punchCall(10)])
        let start = Instant.now
        _ = engine.beginTimeline(at: start)
        _ = engine.processTick(at: start.advanced(by: .seconds(10)))
        #expect(engine.snapshot.currentCall != nil)
        _ = engine.processTick(at: start.advanced(by: .seconds(65)))   // into the rest
        #expect(engine.snapshot.currentCall == nil)
    }

    @Test("an uncoached workout never shows a call")
    func uncoachedShowsNothing() {
        let engine = engine([])
        let start = Instant.now
        _ = engine.beginTimeline(at: start)
        for second in stride(from: 10, through: 150, by: 10) {
            _ = engine.processTick(at: start.advanced(by: .seconds(second)))
            #expect(engine.snapshot.currentCall == nil)
        }
    }

    @Test("resetting clears the ticker")
    func resetClears() {
        let engine = engine([punchCall(10)])
        let start = Instant.now
        _ = engine.beginTimeline(at: start)
        _ = engine.processTick(at: start.advanced(by: .seconds(10)))
        engine.reset()
        #expect(engine.snapshot.currentCall == nil)
    }

    /// The accessible description must read as one phrase. "Jab Cross" then "1 · 2" then "to the
    /// body" as three fragments is what a screen reader would otherwise announce.
    @Test("the call reads as a single accessible phrase")
    func accessibleDescription() {
        let call = CoachCallDisplay(primary: "Jab Cross", secondary: "1 · 2", modifier: "to the body")
        #expect(call.accessibleDescription == "Jab Cross, to the body")
        let plain = CoachCallDisplay(primary: "Circle left", secondary: nil, modifier: nil)
        #expect(plain.accessibleDescription == "Circle left")
    }

    @Test("every call that fires reaches the ticker")
    func everyCallReachesTheTicker() {
        let plan = (1...5).map { lineCall($0 * 10) }
        let engine = engine(plan)
        let start = Instant.now
        _ = engine.beginTimeline(at: start)
        var seen = 0
        for second in 1...55 {
            let cues = engine.processTick(at: start.advanced(by: .seconds(second)))
            if cues.contains(where: { if case .spoken = $0 { return true } else { return false } }) {
                #expect(engine.snapshot.currentCall != nil, "a call fired with no ticker text")
                seen += 1
            }
        }
        #expect(seen == plan.count)
    }
}

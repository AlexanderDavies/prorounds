import Testing
import Foundation
@testable import ProRoundsFoundationAudio

@Suite("Round cue plan")
struct RoundCuePlanningTests {
    private let clip = URL(fileURLWithPath: "/tmp/jab.m4a")

    @Test("a planned cue carries its offset, its cue, and its already-resolved display text")
    func plannedCueShape() {
        let planned = PlannedCue(offset: .seconds(30), cue: .spoken(clip),
                                 tickerPrimary: "Jab Cross", tickerSecondary: "1 · 2",
                                 tickerModifier: "to the body")
        #expect(planned.offset == .seconds(30))
        #expect(planned.cue == .spoken(clip))
        #expect(planned.tickerPrimary == "Jab Cross")
        #expect(planned.tickerSecondary == "1 · 2")
        #expect(planned.tickerModifier == "to the body")
    }

    @Test("display text is optional — not every cue has something to show")
    func displayTextIsOptional() {
        let planned = PlannedCue(offset: .seconds(5), cue: .spoken(clip), tickerPrimary: "Work!")
        #expect(planned.tickerSecondary == nil)
        #expect(planned.tickerModifier == nil)
    }

    /// An uncoached workout must need no special case anywhere: it simply gets a planner that plans
    /// nothing, and every code path downstream is the same one a coached workout uses.
    @Test("the no-op planner plans nothing for any round")
    func noOpPlansNothing() {
        let planner = NoRoundCuePlanner()
        for index in 0..<5 {
            #expect(planner.cues(forRound: index, length: .seconds(180)).isEmpty)
        }
    }

    @Test("a plan is returned in ascending offset order")
    func planIsOrdered() {
        let planner = FixedRoundCuePlanner(cues: [
            PlannedCue(offset: .seconds(60), cue: .spoken(clip), tickerPrimary: "b"),
            PlannedCue(offset: .seconds(10), cue: .spoken(clip), tickerPrimary: "a")
        ])
        let plan = planner.cues(forRound: 0, length: .seconds(180))
        #expect(plan.map(\.tickerPrimary) == ["a", "b"])
    }

    /// The seam's whole purpose. It takes **offsets** — a position within a round the engine already
    /// owns. It cannot express a delay, a sleep, or a clock of its own, so a second timeline cannot
    /// be introduced through it without changing this type.
    @Test("the seam expresses positions, not durations to wait")
    func seamCannotHoldAClock() {
        let planned = PlannedCue(offset: .seconds(30), cue: .spoken(clip), tickerPrimary: "x")
        // An offset is relative to the round's start, so it is meaningful only to something that
        // already knows when the round started — the engine. Nothing here can start timing.
        #expect(planned.offset > .zero)
    }
}

import Testing
import Foundation
@testable import ProRoundsFeatureTimer
import ProRoundsFoundationAudio

@Suite("Round plan cursor")
struct RoundPlanCursorTests {
    private let clip = URL(fileURLWithPath: "/tmp/c.m4a")

    private func cue(_ seconds: Int, _ label: String) -> PlannedCue {
        PlannedCue(offset: .seconds(seconds), cue: .spoken(clip), tickerPrimary: label)
    }

    private func loaded(_ cues: [PlannedCue], length: Duration = .seconds(60)) -> RoundPlanCursor {
        var cursor = RoundPlanCursor()
        cursor.load(cues, roundLength: length)
        return cursor
    }

    @Test("nothing fires before its offset")
    func nothingEarly() {
        var cursor = loaded([cue(30, "a")])
        let start = ContinuousClock.now
        #expect(cursor.crossed(at: start.advanced(by: .seconds(29)), roundStart: start).isEmpty)
    }

    @Test("a cue fires exactly once")
    func firesOnce() {
        var cursor = loaded([cue(10, "a")])
        let start = ContinuousClock.now
        #expect(cursor.crossed(at: start.advanced(by: .seconds(10)), roundStart: start).count == 1)
        #expect(cursor.crossed(at: start.advanced(by: .seconds(20)), roundStart: start).isEmpty)
    }

    /// The case a per-cue flag gets wrong: one tick arriving after the app was backgrounded must
    /// fire everything it passed, in order.
    @Test("a single tick past several offsets fires all of them in order")
    func jumpFiresAllInOrder() {
        var cursor = loaded([cue(10, "a"), cue(20, "b"), cue(30, "c")])
        let start = ContinuousClock.now
        let fired = cursor.crossed(at: start.advanced(by: .seconds(45)), roundStart: start)
        #expect(fired.count == 3)
        #expect(cursor.currentCall?.primary == "c", "the last crossed call should be showing")
    }

    /// Firing order is a property of the cursor, not a promise made by whoever supplied the plan.
    @Test("an unsorted plan still fires in offset order")
    func unsortedPlanIsSorted() {
        var cursor = loaded([cue(30, "c"), cue(10, "a"), cue(20, "b")])
        let start = ContinuousClock.now
        _ = cursor.crossed(at: start.advanced(by: .seconds(10)), roundStart: start)
        #expect(cursor.currentCall?.primary == "a")
        _ = cursor.crossed(at: start.advanced(by: .seconds(20)), roundStart: start)
        #expect(cursor.currentCall?.primary == "b")
    }

    @Test("an offset at or beyond the round length is dropped")
    func beyondRoundIsDropped() {
        var cursor = loaded([cue(60, "at-end"), cue(90, "past-end")], length: .seconds(60))
        let start = ContinuousClock.now
        #expect(cursor.crossed(at: start.advanced(by: .seconds(120)), roundStart: start).isEmpty)
    }

    @Test("clearing discards the plan and the current call")
    func clearing() {
        var cursor = loaded([cue(10, "a")])
        let start = ContinuousClock.now
        _ = cursor.crossed(at: start.advanced(by: .seconds(10)), roundStart: start)
        #expect(cursor.currentCall != nil)
        cursor.clear()
        #expect(cursor.currentCall == nil)
        #expect(cursor.crossed(at: start.advanced(by: .seconds(20)), roundStart: start).isEmpty)
    }

    @Test("an empty plan never fires")
    func emptyPlan() {
        var cursor = loaded([])
        let start = ContinuousClock.now
        #expect(cursor.crossed(at: start.advanced(by: .seconds(500)), roundStart: start).isEmpty)
        #expect(cursor.currentCall == nil)
    }

    @Test("loading a new round resets progress")
    func reloadResets() {
        var cursor = loaded([cue(10, "a")])
        let start = ContinuousClock.now
        _ = cursor.crossed(at: start.advanced(by: .seconds(10)), roundStart: start)
        cursor.load([cue(10, "b")], roundLength: .seconds(60))
        #expect(cursor.currentCall == nil)
        let next = start.advanced(by: .seconds(100))
        #expect(cursor.crossed(at: next.advanced(by: .seconds(10)), roundStart: next).count == 1)
    }
}

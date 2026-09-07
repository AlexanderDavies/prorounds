import Foundation
import ProRoundsFoundationAudio

/// Tracks how far through a round's planned cues the clock has reached.
///
/// Extracted from the engine because it is the piece most exposed to an off-by-one: cues must fire
/// once each, in order, and a resume from the background crosses several offsets in a single tick.
/// Keeping it here makes that mechanism testable on its own rather than only through a workout.
///
/// It holds no clock. It is told an instant and the round's start, and reports what that crossed.
struct RoundPlanCursor {
    private var plan: [PlannedCue] = []
    private var next = 0

    /// The call currently being said, or nil when the coach is silent.
    private(set) var currentCall: CoachCallDisplay?

    /// Takes a round's plan, dropping anything that could never be reached.
    ///
    /// Sorting here rather than trusting the planner keeps the firing order a property of this type,
    /// so a planner that returned cues out of order would still fire them correctly.
    mutating func load(_ cues: [PlannedCue], roundLength: Duration) {
        plan = cues.filter { $0.offset < roundLength }.sorted { $0.offset < $1.offset }
        next = 0
        currentCall = nil
    }

    mutating func clear() {
        plan = []
        next = 0
        currentCall = nil
    }

    /// Cues whose offsets `now` has reached, in order. Each is returned exactly once.
    ///
    /// A `while` rather than a single check: a tick can arrive long after the last one — the app was
    /// backgrounded, the device slept — and every cue it passed must still fire, in order, none
    /// skipped and none repeated.
    mutating func crossed(at now: ContinuousClock.Instant,
                          roundStart: ContinuousClock.Instant) -> [AudioCue] {
        var fired: [AudioCue] = []
        while next < plan.count {
            let planned = plan[next]
            guard now >= roundStart.advanced(by: planned.offset) else { break }
            fired.append(planned.cue)
            currentCall = CoachCallDisplay(
                primary: planned.tickerPrimary,
                secondary: planned.tickerSecondary,
                modifier: planned.tickerModifier)
            next += 1
        }
        return fired
    }
}

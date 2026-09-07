import Testing
import Foundation
@testable import ProRoundsFoundationCoaching

/// Properties asserted over many generated rounds rather than pinned to fixture values.
///
/// The distinction matters for `estMs`: those are measured clip durations, rewritten every time the
/// voice is re-recorded. A test that hardcoded millisecond totals would need editing after each
/// re-record and would quietly stop meaning anything. These assert the *guarantee* instead, so a
/// re-record that breaks a guard fails loudly.
@Suite("Scheduler invariants")
struct SchedulerPropertyTests {
    private static let rounds: [Int] = Array(stride(from: 30_000, through: 300_000, by: 15_000))
    private static let configs = ["demo", "alpha", "bravo", "", "a-longer-config-id"]

    /// Every round the suite exercises: 2 scripts x 19 lengths x 5 configs x 3 indices.
    private func eachRound(
        _ body: (CoachScript, CoachCatalog, Int, [ScheduledCue]) throws -> Void
    ) throws {
        let catalog = try CoachCatalog.bundled()
        let scheduler = CoachCueScheduler(catalog: catalog)
        for name in CoachScript.bundledNames {
            let script = try CoachScript.bundled(name)
            for roundMs in Self.rounds {
                for config in Self.configs {
                    for index in 0..<3 {
                        let calls = scheduler.schedule(
                            script: script, roundMs: roundMs, warningMs: 10_000,
                            configID: config, roundIndex: index)
                        try body(script, catalog, roundMs, calls)
                    }
                }
            }
        }
    }

    @Test("no cue is still speaking inside the end-of-round guard")
    func nothingSpeaksAtTheBell() throws {
        try eachRound { script, catalog, roundMs, calls in
            let lastEnd = roundMs - script.guards.roundEndGuardMs
            for cue in calls {
                let phrase = try #require(catalog[cue.phraseID])
                #expect(cue.offsetMs + phrase.estMs <= lastEnd,
                        "\(cue.phraseID) ends at \(cue.offsetMs + phrase.estMs), past \(lastEnd)")
            }
        }
    }

    @Test("no cue starts before the round-start delay")
    func nothingSpeaksOverTheBell() throws {
        try eachRound { script, _, _, calls in
            for cue in calls {
                #expect(cue.offsetMs >= script.guards.roundStartDelayMs,
                        "\(cue.phraseID) starts at \(cue.offsetMs)")
            }
        }
    }

    @Test("every cue falls inside its round")
    func cuesStayInsideTheRound() throws {
        try eachRound { _, _, roundMs, calls in
            for cue in calls {
                #expect(cue.offsetMs >= 0 && cue.offsetMs < roundMs)
            }
        }
    }

    @Test("cues come back in ascending order")
    func ordered() throws {
        try eachRound { _, _, _, calls in
            #expect(calls == calls.sorted())
        }
    }

    @Test("a round too short for any call returns empty rather than throwing")
    func shortRoundsAreEmptyNotFatal() throws {
        let catalog = try CoachCatalog.bundled()
        let scheduler = CoachCueScheduler(catalog: catalog)
        for name in CoachScript.bundledNames {
            let script = try CoachScript.bundled(name)
            for roundMs in [0, 1, 100, 1_000, 2_000, 4_000] {
                let calls = scheduler.schedule(script: script, roundMs: roundMs, warningMs: 10_000,
                                               configID: "short", roundIndex: 0)
                #expect(calls.isEmpty, "\(name) at \(roundMs)ms produced \(calls.count) calls")
            }
        }
    }

    @Test("warnings off is handled")
    func noWarningCue() throws {
        let catalog = try CoachCatalog.bundled()
        let scheduler = CoachCueScheduler(catalog: catalog)
        let script = try CoachScript.bundled("beginner_shadow")
        let calls = scheduler.schedule(script: script, roundMs: 180_000, warningMs: 0,
                                       configID: "demo", roundIndex: 0)
        #expect(!calls.isEmpty)
        for cue in calls {
            let phrase = try #require(catalog[cue.phraseID])
            #expect(cue.offsetMs + phrase.estMs <= 180_000 - script.guards.roundEndGuardMs)
        }
    }

    /// The adjacency rule governs the **drawn** sequence, but this asserts the **delivered** one,
    /// and the two can differ for two reasons — both reference behaviour, verified against
    /// `coach-script.py`, not port bugs:
    ///
    /// 1. Pinned cues are placed before the walk and merged at the end, so the walk's counter never
    ///    sees them. A pinned `effort_last_ten` can land after two drawn non-combos.
    /// 2. Two calls can share an offset at a segment boundary, and the `(offset, id, kind)` sort
    ///    then orders them by phrase id rather than by when they were drawn — which can turn a
    ///    two-run into a three-run. `edge_offset_tie.json` is the fixture for that case.
    ///
    /// So the invariant is: an over-long run always involves a pinned cue or an offset tie. That
    /// still fails loudly if the adjacency rule itself regresses, which an unconditional
    /// `run <= max` could not, since it would simply have to be deleted.
    @Test("an over-long non-combo run always involves a pinned cue or an offset tie")
    func longNonComboRunsAreExplained() throws {
        try eachRound { script, _, _, calls in
            let pinnedIDs = Set(script.segments.flatMap(\.pinned).map(\.id))
            let tiedOffsets = Set(Dictionary(grouping: calls, by: \.offsetMs)
                .filter { $0.value.count > 1 }.keys)
            var run: [ScheduledCue] = []
            for cue in calls {
                run = cue.kind == .combo ? [] : run + [cue]
                guard run.count > script.guards.maxConsecutiveNonCombo else { continue }
                let explained = run.contains { pinnedIDs.contains($0.phraseID) }
                    || run.contains { tiedOffsets.contains($0.offsetMs) }
                let chain = run.map(\.phraseID).joined(separator: " -> ")
                #expect(explained, "\(run.count) unexplained non-combos in a row: \(chain)")
            }
        }
    }

    /// Counted per kind: a technique cue waits for N other *technique* cues, not N calls.
    ///
    /// Drawn calls only. The scheduler has a last-resort fallback that ignores the no-repeat filter
    /// when every candidate is blocked, and pinned cues are seeded into the history without passing
    /// through it, so both are excluded here rather than asserted away.
    @Test("no phrase repeats inside its per-kind window")
    func noRepeatWithinKindWindow() throws {
        try eachRound { script, _, _, calls in
            let pinnedIDs = Set(script.segments.flatMap(\.pinned).map(\.id))
            var history: [CoachKind: [String]] = [:]
            for cue in calls where !pinnedIDs.contains(cue.phraseID) {
                let window = script.guards.noRepeatWithinKind[cue.kind] ?? 0
                let recent = history[cue.kind, default: []].suffix(window)
                #expect(!recent.contains(cue.phraseID),
                        "\(cue.phraseID) repeated inside its \(window)-cue \(cue.kind.rawValue) window")
                history[cue.kind, default: []].append(cue.phraseID)
            }
        }
    }

    @Test("the scheduler has no clock dependency")
    func noClockDependency() throws {
        // Constructed from a catalog alone — there is no TimeSource to inject, so the type cannot
        // observe time, and it returns offsets rather than deadlines so it cannot extend a round.
        let scheduler = CoachCueScheduler(catalog: try CoachCatalog.bundled())
        let script = try CoachScript.bundled("beginner_bag")
        let early = scheduler.schedule(script: script, roundMs: 120_000, warningMs: 10_000,
                                       configID: "clock", roundIndex: 0)
        Thread.sleep(forTimeInterval: 0.05)
        let later = scheduler.schedule(script: script, roundMs: 120_000, warningMs: 10_000,
                                       configID: "clock", roundIndex: 0)
        #expect(early == later)
    }
}

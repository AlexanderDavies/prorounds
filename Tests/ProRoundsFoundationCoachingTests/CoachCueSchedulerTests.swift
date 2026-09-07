import Testing
import Foundation
@testable import ProRoundsFoundationCoaching

private struct ScheduleFixture: Decodable {
    struct Call: Decodable {
        let offsetMs: Int
        let phraseId: String
        let kind: String
    }
    let script: String
    let roundMs: Int
    let warningMs: Int
    let roundIndex: Int
    let configId: String
    let calls: [Call]

    var name: String { "\(script) r\(roundMs / 1000)s i\(roundIndex)" }

    static func all() throws -> [ScheduleFixture] {
        let urls = try #require(Bundle.module.urls(
            forResourcesWithExtension: "json", subdirectory: "Fixtures/schedules"))
        return try urls.sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { try JSONDecoder().decode(ScheduleFixture.self, from: Data(contentsOf: $0)) }
    }
}

@Suite("Scheduler matches the Python reference")
struct CoachCueSchedulerTests {
    /// The whole point of this change. `scripts/coach-script.py` is normative; a divergence here is
    /// a bug in Swift, not in the fixture. 48 fixtures span 4-300s across three round indices.
    @Test("every fixture reproduces byte for byte")
    func matchesEveryFixture() throws {
        let catalog = try CoachCatalog.bundled()
        let scheduler = CoachCueScheduler(catalog: catalog)
        let fixtures = try ScheduleFixture.all()
        #expect(fixtures.count == 49, "expected 49 fixtures, found \(fixtures.count)")

        for fixture in fixtures {
            let script = try CoachScript.bundled(fixture.script)
            let actual = scheduler.schedule(
                script: script, roundMs: fixture.roundMs, warningMs: fixture.warningMs,
                configID: fixture.configId, roundIndex: fixture.roundIndex)

            #expect(actual.count == fixture.calls.count,
                    "\(fixture.name): got \(actual.count) calls, expected \(fixture.calls.count)")
            for (index, expected) in fixture.calls.enumerated() where index < actual.count {
                let got = actual[index]
                let detail = "\(fixture.name) call \(index): got "
                    + "(\(got.offsetMs), \(got.phraseID), \(got.kind.rawValue)) expected "
                    + "(\(expected.offsetMs), \(expected.phraseId), \(expected.kind))"
                #expect(got.offsetMs == expected.offsetMs && got.phraseID == expected.phraseId
                        && got.kind.rawValue == expected.kind, "\(detail)")
            }
        }
    }

    @Test("fixtures cover the empty-schedule guard path")
    func fixturesCoverEmptySchedules() throws {
        #expect(try ScheduleFixture.all().filter { $0.calls.isEmpty }.count == 4)
    }

    @Test("scheduling the same round twice returns the same schedule")
    func replaysIdentically() throws {
        let scheduler = CoachCueScheduler(catalog: try CoachCatalog.bundled())
        let script = try CoachScript.bundled("beginner_shadow")
        let once = scheduler.schedule(script: script, roundMs: 180_000, warningMs: 10_000,
                                      configID: "abc", roundIndex: 2)
        let twice = scheduler.schedule(script: script, roundMs: 180_000, warningMs: 10_000,
                                       configID: "abc", roundIndex: 2)
        #expect(once == twice)
        #expect(!once.isEmpty)
    }

    @Test("consecutive rounds of one workout differ")
    func roundsDiffer() throws {
        let scheduler = CoachCueScheduler(catalog: try CoachCatalog.bundled())
        let script = try CoachScript.bundled("beginner_shadow")
        let first = scheduler.schedule(script: script, roundMs: 180_000, warningMs: 10_000,
                                       configID: "abc", roundIndex: 0)
        let second = scheduler.schedule(script: script, roundMs: 180_000, warningMs: 10_000,
                                        configID: "abc", roundIndex: 1)
        #expect(first != second)
    }

    /// Python's `round()` is half-to-even; Swift's `rounded()` defaults to half-away-from-zero.
    /// This cannot be reached through a fixture — exact `.5` never arises from the cadence walk
    /// (0 across 212,748 sampled values) — so the helper is tested directly.
    @Test("offsets round half-to-even, matching Python")
    func banker() {
        #expect(roundedOffset(0.5) == 0)
        #expect(roundedOffset(1.5) == 2)
        #expect(roundedOffset(2.5) == 2)
        #expect(roundedOffset(3.5) == 4)
        #expect(roundedOffset(-0.5) == 0)
        #expect(roundedOffset(2.4) == 2)
        #expect(roundedOffset(2.6) == 3)
    }
}

@Suite("Cue ordering")
struct ScheduledCueOrderingTests {
    private func cue(_ offset: Int, _ id: String, _ kind: CoachKind = .combo) -> ScheduledCue {
        ScheduledCue(offsetMs: offset, phraseID: id, kind: kind)
    }

    @Test("offset orders first")
    func offsetFirst() {
        #expect(cue(100, "z") < cue(200, "a"))
    }

    /// The tie-break no fixture reaches: a pinned cue landing exactly on a drawn one. Python sorts
    /// the whole tuple, so equal offsets fall back to phrase id and then kind.
    @Test("equal offsets break on phrase id, then kind")
    func tieBreak() {
        #expect(cue(100, "alpha") < cue(100, "beta"))
        #expect(!(cue(100, "beta") < cue(100, "alpha")))
        #expect(cue(100, "same", .combo) < cue(100, "same", .defence))
        #expect(cue(100, "same", .defence) < cue(100, "same", .effort))
    }

    @Test("sorting a mixed batch matches the reference ordering")
    func sortsLikePython() {
        let sorted = [cue(200, "b"), cue(100, "z"), cue(100, "a"), cue(150, "m")].sorted()
        #expect(sorted.map(\.phraseID) == ["a", "z", "m", "b"])
    }
}

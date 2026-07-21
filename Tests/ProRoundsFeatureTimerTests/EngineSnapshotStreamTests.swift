import Testing
import Foundation
@testable import ProRoundsFeatureTimer

@MainActor
@Suite("RoundTimerEngine — snapshots stream")
struct EngineSnapshotStreamTests {
    @Test("The stream yields the initial snapshot and updates as the workout advances")
    func streamYieldsProgression() async {
        let engine = EngineFixture.make(prep: 0, round: 5, rest: 0, rounds: 1, lead: 0)
        var iterator = engine.snapshots.makeAsyncIterator()

        let initial = await iterator.next()
        #expect(initial?.phase == .round(index: 1))
        #expect(initial?.remaining == .seconds(5))

        let t0 = ContinuousClock().now
        _ = engine.beginTimeline(at: t0)
        let started = await iterator.next()
        #expect(started?.phase == .round(index: 1))

        _ = engine.processTick(at: t0.advanced(by: .seconds(5)))
        // Drain to the finished snapshot.
        var latest = started
        for _ in 0..<4 {
            if let next = await iterator.next() { latest = next }
            if latest?.phase == .finished { break }
        }
        #expect(latest?.phase == .finished)
    }
}

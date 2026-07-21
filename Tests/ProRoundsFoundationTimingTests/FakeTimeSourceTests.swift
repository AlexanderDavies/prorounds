import Testing
import Foundation
@testable import ProRoundsFoundationTiming

@Suite("FakeTimeSource")
struct FakeTimeSourceTests {
    @Test("Reads are stable when time is not advanced")
    func stableReads() {
        let fake = FakeTimeSource()
        let first = fake.now
        let second = fake.now
        #expect(first == second)
    }

    @Test("Advancing moves now forward by exactly the requested duration")
    func advanceIsExact() {
        let fake = FakeTimeSource()
        let start = fake.now
        fake.advance(by: .seconds(5))
        #expect(start.duration(to: fake.now) == .seconds(5))

        fake.advance(by: .milliseconds(250))
        #expect(start.duration(to: fake.now) == .seconds(5) + .milliseconds(250))
    }

    @Test("Work scheduled at or before the new instant fires when time advances past it")
    func dueSleepersFire() async throws {
        let fake = FakeTimeSource()
        let deadline = fake.now.advanced(by: .seconds(3))

        let task = Task { try await fake.sleep(until: deadline) }
        // Wait for the sleeper to register so advancing is deterministic.
        while fake.pendingSleeperCount == 0 { await Task.yield() }

        fake.advance(by: .seconds(3))
        try await task.value // completes without hanging
        #expect(fake.pendingSleeperCount == 0)
    }

    @Test("A sleep whose deadline is already in the past returns immediately")
    func pastDeadlineReturnsImmediately() async throws {
        let fake = FakeTimeSource()
        let past = fake.now // deadline == now → already due
        try await fake.sleep(until: past)
        #expect(fake.pendingSleeperCount == 0)
    }

    @Test("Advancing short of a deadline leaves the sleeper pending")
    func partialAdvanceKeepsSleeperPending() async throws {
        let fake = FakeTimeSource()
        let deadline = fake.now.advanced(by: .seconds(10))
        let task = Task { try await fake.sleep(until: deadline) }
        while fake.pendingSleeperCount == 0 { await Task.yield() }

        fake.advance(by: .seconds(4))
        #expect(fake.pendingSleeperCount == 1) // not yet due

        fake.advance(by: .seconds(6)) // now at the deadline
        try await task.value
        #expect(fake.pendingSleeperCount == 0)
    }
}

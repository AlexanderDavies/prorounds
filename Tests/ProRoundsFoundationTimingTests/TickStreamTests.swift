import Testing
import Foundation
@testable import ProRoundsFoundationTiming

@Suite("TimeSource tick stream")
struct TickStreamTests {
    @Test("FakeTimeSource yields a tick only when the test emits one")
    func fakeEmitsOnDemand() async throws {
        let fake = FakeTimeSource()
        var iterator = fake.ticks(interval: .milliseconds(100)).makeAsyncIterator()

        fake.advance(by: .seconds(1))
        fake.emitTick()
        let first = try #require(await iterator.next())

        fake.advanceAndTick(by: .seconds(2))
        let second = try #require(await iterator.next())
        // The second tick is 2s after the first.
        #expect(first.duration(to: second) == .seconds(2))
    }

    @Test("Real source yields monotonic ticks roughly at the interval")
    func realTicksMonotonic() async throws {
        let source = RealTimeSource()
        var instants: [ContinuousClock.Instant] = []
        for await instant in source.ticks(interval: .milliseconds(10)) {
            instants.append(instant)
            if instants.count == 3 { break }
        }
        #expect(instants.count == 3)
        #expect(instants[0] <= instants[1])
        #expect(instants[1] <= instants[2])
    }
}

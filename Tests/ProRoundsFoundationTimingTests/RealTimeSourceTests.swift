import Testing
import Foundation
@testable import ProRoundsFoundationTiming

@Suite("RealTimeSource")
struct RealTimeSourceTests {
    @Test("Successive instants are monotonic non-decreasing")
    func monotonic() {
        let source = RealTimeSource()
        let first = source.now
        let second = source.now
        #expect(second >= first)
    }

    @Test("sleep(for:) suspends for at least the requested duration")
    func sleepRespectsDuration() async throws {
        let source = RealTimeSource()
        let start = source.now
        try await source.sleep(for: .milliseconds(20))
        #expect(start.duration(to: source.now) >= .milliseconds(20))
    }
}

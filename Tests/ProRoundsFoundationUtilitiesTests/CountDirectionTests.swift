import Testing
@testable import ProRoundsFoundationUtilities

@Suite("CountDirection")
struct CountDirectionTests {
    @Test("Has count down and count up")
    func cases() {
        #expect(CountDirection.allCases == [.countDown, .countUp])
    }
}

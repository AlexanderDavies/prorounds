import Testing
import Foundation
@testable import ProRoundsFoundationUtilities

@Suite("DurationFormat.clock")
struct DurationFormatClockTests {
    @Test("Sub-hour duration formats as m:ss")
    func subHour() {
        #expect(DurationFormat.clock(.seconds(83)) == "1:23")
        #expect(DurationFormat.clock(.seconds(120)) == "2:00")
        #expect(DurationFormat.clock(.seconds(2830)) == "47:10")
    }

    @Test("Hour-or-more duration includes hours with padded minutes")
    func withHours() {
        #expect(DurationFormat.clock(.seconds(3723)) == "1:02:03")
    }

    @Test("Zero and sub-second durations format as 0:00")
    func zero() {
        #expect(DurationFormat.clock(.seconds(0)) == "0:00")
        #expect(DurationFormat.clock(.milliseconds(400)) == "0:00")
    }
}

@Suite("DurationFormat.compactMinutes")
struct DurationFormatCompactTests {
    @Test("Whole minutes render as Nmin")
    func wholeMinutes() {
        #expect(DurationFormat.compactMinutes(.seconds(180)) == "3min")
        #expect(DurationFormat.compactMinutes(.seconds(60)) == "1min")
    }

    @Test("Durations with seconds render as m:ss")
    func withSeconds() {
        #expect(DurationFormat.compactMinutes(.seconds(30)) == "0:30")
        #expect(DurationFormat.compactMinutes(.seconds(210)) == "3:30")
    }
}

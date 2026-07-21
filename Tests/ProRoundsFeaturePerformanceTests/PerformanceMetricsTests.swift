import Testing
import Foundation
@testable import ProRoundsFeaturePerformance
import ProRoundsDataSessions
import ProRoundsFoundationUtilities

enum MetricsFixture {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }
    static let reference = Date(timeIntervalSince1970: 1_700_000_000)

    /// A session whose active minutes = roundMinutes × rounds.
    static func session(_ type: WorkoutType, roundMinutes: Int, rounds: Int, daysAgo: Int) -> Session {
        Session(
            date: calendar.date(byAdding: .day, value: -daysAgo, to: reference) ?? reference,
            workoutType: type, configurationName: "\(type)",
            rounds: rounds, roundDuration: .seconds(roundMinutes * 60),
            restDuration: .seconds(60), prepDuration: .seconds(10),
            roundsCompleted: rounds, totalDuration: .seconds(0)
        )
    }
}

@Suite("PerformanceMetrics")
struct PerformanceMetricsTests {
    private func make(_ sessions: [Session], range: PerformanceRange) -> PerformanceData {
        PerformanceMetrics.make(sessions: sessions, range: range,
                                referenceDate: MetricsFixture.reference, calendar: MetricsFixture.calendar)
    }

    @Test("Produces a series per type plus a total equal to the per-bucket sum")
    func perTypeAndTotal() {
        let sessions = [
            MetricsFixture.session(.heavyBag, roundMinutes: 3, rounds: 12, daysAgo: 1), // 36 min
            MetricsFixture.session(.skipping, roundMinutes: 2, rounds: 5, daysAgo: 1)   // 10 min, same day
        ]
        let data = make(sessions, range: .week)
        let ids = data.series.map(\.id)
        #expect(ids.contains(.type(.heavyBag)))
        #expect(ids.contains(.type(.skipping)))
        #expect(ids.contains(.total))

        // Same day → total bucket = 36 + 10 = 46.
        let totalSeries = data.series.first { $0.id == .total }
        #expect(totalSeries?.points.map(\.minutes) == [46])
    }

    @Test("Active minutes exclude rest and prep")
    func activeMinutesOnly() {
        let data = make([MetricsFixture.session(.heavyBag, roundMinutes: 3, rounds: 12, daysAgo: 1)], range: .week)
        #expect(data.summary.activeMinutes == 36) // 12 × 3, not the total workout time
    }

    @Test("Range filtering restricts sessions")
    func rangeFiltering() {
        let sessions = [
            MetricsFixture.session(.heavyBag, roundMinutes: 3, rounds: 10, daysAgo: 3),   // in week
            MetricsFixture.session(.heavyBag, roundMinutes: 3, rounds: 10, daysAgo: 20),  // in month
            MetricsFixture.session(.heavyBag, roundMinutes: 3, rounds: 10, daysAgo: 100) // only in all
        ]
        #expect(make(sessions, range: .week).summary.sessionCount == 1)
        #expect(make(sessions, range: .month).summary.sessionCount == 2)
        #expect(make(sessions, range: .all).summary.sessionCount == 3)
    }

    @Test("Summary reports active minutes, session count, and rounds")
    func summary() {
        let sessions = (0..<3).map { _ in MetricsFixture.session(.sparring, roundMinutes: 3, rounds: 10, daysAgo: 1) }
        let summary = make(sessions, range: .week).summary
        #expect(summary.activeMinutes == 90) // 3 × 30
        #expect(summary.sessionCount == 3)
        #expect(summary.rounds == 30)
    }

    @Test("No sessions yields empty data")
    func empty() {
        #expect(make([], range: .all).isEmpty)
        #expect(make([], range: .all).summary == .zero)
    }
}

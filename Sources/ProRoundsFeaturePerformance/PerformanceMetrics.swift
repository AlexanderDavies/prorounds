import Foundation
import ProRoundsDataSessions
import ProRoundsFoundationUtilities

/// The time window for the performance view.
public enum PerformanceRange: String, CaseIterable, Sendable {
    case week, month, all

    var label: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .all: return "All"
        }
    }

    /// Bucket granularity: recent ranges bucket per day; All buckets per week.
    var bucketComponent: Calendar.Component {
        switch self {
        case .week, .month: return .day
        case .all: return .weekOfYear
        }
    }

    func contains(_ date: Date, referenceDate: Date, calendar: Calendar) -> Bool {
        switch self {
        case .all:
            return date <= referenceDate
        case .week:
            guard let cutoff = calendar.date(byAdding: .day, value: -7, to: referenceDate) else { return false }
            return date >= cutoff && date <= referenceDate
        case .month:
            guard let cutoff = calendar.date(byAdding: .day, value: -30, to: referenceDate) else { return false }
            return date >= cutoff && date <= referenceDate
        }
    }
}

/// Identifies a chart series: one per workout type, plus a total aggregate.
enum SeriesID: Hashable, Sendable {
    case type(WorkoutType)
    case total

    var label: String {
        switch self {
        case .type(let type): return type.displayName
        case .total: return "Total"
        }
    }

    var workoutType: WorkoutType? {
        if case .type(let type) = self { return type }
        return nil
    }

    var isTotal: Bool { self == .total }
}

struct PerformancePoint: Equatable, Sendable {
    let date: Date
    let minutes: Double
}

struct PerformanceSeries: Identifiable, Equatable, Sendable {
    let id: SeriesID
    let points: [PerformancePoint]
}

struct PerformanceSummary: Equatable, Sendable {
    let activeMinutes: Int
    let sessionCount: Int
    let rounds: Int

    static let zero = PerformanceSummary(activeMinutes: 0, sessionCount: 0, rounds: 0)
}

struct PerformanceData: Equatable, Sendable {
    let series: [PerformanceSeries] // per-type in spec order, then total
    let summary: PerformanceSummary

    var isEmpty: Bool { series.isEmpty }
}

/// Pure aggregation of sessions into active-minutes-over-time series + summary figures (DESIGN §7.4).
/// Takes `referenceDate`/`calendar` so range filtering and bucketing are deterministic.
enum PerformanceMetrics {
    static func make(
        sessions: [Session],
        range: PerformanceRange,
        referenceDate: Date,
        calendar: Calendar
    ) -> PerformanceData {
        let inRange = sessions.filter { range.contains($0.date, referenceDate: referenceDate, calendar: calendar) }

        let summary = PerformanceSummary(
            activeMinutes: Int(inRange.reduce(0.0) { $0 + minutes($1.activeDuration) }.rounded()),
            sessionCount: inRange.count,
            rounds: inRange.reduce(0) { $0 + $1.roundsCompleted }
        )

        let component = range.bucketComponent
        var series: [PerformanceSeries] = []
        for type in WorkoutType.allCases {
            let ofType = inRange.filter { $0.workoutType == type }
            guard !ofType.isEmpty else { continue }
            series.append(PerformanceSeries(id: .type(type),
                                            points: bucket(ofType, component: component, calendar: calendar)))
        }
        if !inRange.isEmpty {
            series.append(PerformanceSeries(id: .total,
                                            points: bucket(inRange, component: component, calendar: calendar)))
        }

        return PerformanceData(series: series, summary: summary)
    }

    private static func bucket(
        _ sessions: [Session],
        component: Calendar.Component,
        calendar: Calendar
    ) -> [PerformancePoint] {
        var totals: [Date: Double] = [:]
        for session in sessions {
            let start = calendar.dateInterval(of: component, for: session.date)?.start
                ?? calendar.startOfDay(for: session.date)
            totals[start, default: 0] += minutes(session.activeDuration)
        }
        return totals.sorted { $0.key < $1.key }.map { PerformancePoint(date: $0.key, minutes: $0.value) }
    }

    private static func minutes(_ duration: Duration) -> Double {
        Double(duration.components.seconds) / 60
    }
}

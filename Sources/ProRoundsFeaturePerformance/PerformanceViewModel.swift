import Foundation
import Observation
import ProRoundsDataSessions

/// View model for the Performance tab (guide §3.2). Loads sessions once and recomputes the chart
/// data via the pure `PerformanceMetrics` when the range changes; the legend toggle only affects
/// which series are visible. No timer math, no formatting beyond delegating to the aggregator.
@MainActor
@Observable
public final class PerformanceViewModel {
    private(set) var isLoaded = false
    private(set) var range: PerformanceRange = .week
    private(set) var hiddenSeries: Set<SeriesID> = []
    private(set) var data: PerformanceData = PerformanceData(series: [], summary: .zero)

    private var sessions: [Session] = []
    private let repository: any SessionRepository
    private let calendar: Calendar
    private let now: () -> Date

    public init(
        sessions: any SessionRepository,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() }
    ) {
        self.repository = sessions
        self.calendar = calendar
        self.now = now
    }

    /// True only when there are no sessions at all — an empty *range* still shows the chart frame.
    var isEmpty: Bool { isLoaded && sessions.isEmpty }

    var visibleSeries: [PerformanceSeries] {
        data.series.filter { !hiddenSeries.contains($0.id) }
    }

    func load() async {
        sessions = (try? await repository.all()) ?? []
        isLoaded = true
        recompute()
    }

    func setRange(_ range: PerformanceRange) {
        self.range = range
        recompute()
    }

    func toggle(_ id: SeriesID) {
        if hiddenSeries.contains(id) { hiddenSeries.remove(id) } else { hiddenSeries.insert(id) }
    }

    func isHidden(_ id: SeriesID) -> Bool { hiddenSeries.contains(id) }

    private func recompute() {
        data = PerformanceMetrics.make(sessions: sessions, range: range,
                                       referenceDate: now(), calendar: calendar)
    }
}

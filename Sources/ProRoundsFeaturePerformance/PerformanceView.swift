import SwiftUI
import Charts
import ProRoundsDesignSystem
import ProRoundsFoundationUtilities

/// The pure content of the Performance screen — renders injected `PerformanceData` with Swift Charts
/// and forwards intents. No view model, no fetch, so it snapshots deterministically (guide §13.3).
struct PerformanceContentView: View {
    let data: PerformanceData
    let isEmpty: Bool
    let range: PerformanceRange
    let hidden: Set<SeriesID>
    let onRange: (PerformanceRange) -> Void
    let onToggle: (SeriesID) -> Void

    private var visibleSeries: [PerformanceSeries] { data.series.filter { !hidden.contains($0.id) } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Performance")
                    .fontToken(.display)
                    .foregroundStyle(ProRoundsColor.textPrimary)

                rangeControl

                if isEmpty {
                    emptyState
                } else {
                    summaryTiles
                    chartCard
                    legend
                }
            }
            .padding(Spacing.md)
        }
        .background(ProRoundsColor.canvas)
    }

    private var rangeControl: some View {
        HStack(spacing: 0) {
            ForEach(PerformanceRange.allCases, id: \.self) { option in
                Button { onRange(option) } label: {
                    Text(option.label)
                        .fontToken(.subhead)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xs)
                        .foregroundStyle(option == range ? ProRoundsColor.onAccent : ProRoundsColor.textSecondary)
                        .background(option == range
                            ? AnyShapeStyle(ProRoundsColor.accent) : AnyShapeStyle(.clear))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.xxs)
        .background(ProRoundsColor.surfaceRaised, in: Capsule())
    }

    private var summaryTiles: some View {
        HStack(spacing: Spacing.sm) {
            tile("\(data.summary.activeMinutes)", "active min")
            tile("\(data.summary.sessionCount)", "sessions")
            tile("\(data.summary.rounds)", "rounds")
        }
    }

    private func tile(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(value).fontToken(.title).foregroundStyle(ProRoundsColor.textPrimary)
            Text(label).fontToken(.caption).foregroundStyle(ProRoundsColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(ProRoundsColor.surfaceRaised, in: RoundedRectangle(cornerRadius: Radius.lg))
    }

    private var chartCard: some View {
        Chart {
            ForEach(visibleSeries) { series in
                ForEach(series.points, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Active minutes", point.minutes),
                        series: .value("Series", series.id.label)
                    )
                }
                .foregroundStyle(color(for: series.id))
                .lineStyle(StrokeStyle(lineWidth: series.id.isTotal ? 3 : 2, lineCap: .round))
                .interpolationMethod(.monotone)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(ProRoundsColor.border.opacity(0.5))
                AxisValueLabel().foregroundStyle(ProRoundsColor.textSecondary)
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(ProRoundsColor.textSecondary)
            }
        }
        .frame(height: 240)
        .padding(Spacing.md)
        .background(ProRoundsColor.surfaceRaised, in: RoundedRectangle(cornerRadius: Radius.xl))
        .transaction { $0.animation = nil } // deterministic (no chart animation)
    }

    private var legend: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: Spacing.sm)],
                  alignment: .leading, spacing: Spacing.xs) {
            ForEach(data.series) { series in
                Button { onToggle(series.id) } label: {
                    HStack(spacing: Spacing.xs) {
                        Circle().fill(color(for: series.id)).frame(width: 10, height: 10)
                        Text(series.id.label).fontToken(.caption).foregroundStyle(ProRoundsColor.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                .opacity(hidden.contains(series.id) ? 0.35 : 1)
                .accessibilityLabel("\(series.id.label)\(hidden.contains(series.id) ? ", hidden" : "")")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(ProRoundsColor.textSecondary)
            Text("Complete a workout to see your trends.")
                .fontToken(.body)
                .foregroundStyle(ProRoundsColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.xxxl)
    }

    private func color(for id: SeriesID) -> ThemeColor {
        if let type = id.workoutType { return ProRoundsColor.chartColor(for: type) }
        return ProRoundsColor.textPrimary
    }
}

/// The Performance tab: binds a `PerformanceViewModel` to `PerformanceContentView`.
public struct PerformanceView: View {
    @State private var model: PerformanceViewModel

    public init(model: PerformanceViewModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        PerformanceContentView(
            data: model.data,
            isEmpty: model.isEmpty,
            range: model.range,
            hidden: model.hiddenSeries,
            onRange: { model.setRange($0) },
            onToggle: { model.toggle($0) }
        )
        .task { await model.load() }
    }
}

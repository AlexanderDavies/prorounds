#if canImport(UIKit)
import XCTest
import SwiftUI
import SnapshotTesting
@testable import ProRoundsFeaturePerformance
import ProRoundsDataSessions
import ProRoundsFoundationUtilities

@MainActor
final class PerformanceScreenSnapshotTests: XCTestCase {
    private func populatedData() -> PerformanceData {
        let sessions = [
            MetricsFixture.session(.heavyBag, roundMinutes: 3, rounds: 12, daysAgo: 1),
            MetricsFixture.session(.skipping, roundMinutes: 2, rounds: 8, daysAgo: 2),
            MetricsFixture.session(.heavyBag, roundMinutes: 3, rounds: 10, daysAgo: 4),
            MetricsFixture.session(.sparring, roundMinutes: 3, rounds: 6, daysAgo: 5),
            MetricsFixture.session(.skipping, roundMinutes: 2, rounds: 10, daysAgo: 6)
        ]
        return PerformanceMetrics.make(sessions: sessions, range: .week,
                                       referenceDate: MetricsFixture.reference, calendar: MetricsFixture.calendar)
    }

    private func content(_ data: PerformanceData, isEmpty: Bool = false) -> some View {
        PerformanceContentView(data: data, isEmpty: isEmpty, range: .week, hidden: [],
                               onRange: { _ in }, onToggle: { _ in })
    }

    private func assertScreen(_ view: some View, style: UIUserInterfaceStyle, name: String,
                              testName: String = #function, line: UInt = #line) {
        assertSnapshot(
            of: view,
            as: .image(perceptualPrecision: 0.98, layout: .fixed(width: 393, height: 852),
                       traits: UITraitCollection(userInterfaceStyle: style)),
            named: name, testName: testName, line: line
        )
    }

    func test_populated_dark() { assertScreen(content(populatedData()), style: .dark, name: "dark") }
    func test_populated_light() { assertScreen(content(populatedData()), style: .light, name: "light") }
    func test_empty_dark() {
        assertScreen(content(PerformanceData(series: [], summary: .zero), isEmpty: true),
                     style: .dark, name: "empty-dark")
    }
}
#endif

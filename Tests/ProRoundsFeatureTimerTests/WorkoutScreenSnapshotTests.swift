#if canImport(UIKit)
import XCTest
import SwiftUI
import SnapshotTesting
@testable import ProRoundsFeatureTimer
import ProRoundsFoundationUtilities

/// Snapshot tests for the running screen across phases (rendered from a fixed `WorkoutDisplayModel`,
/// so no live engine is involved). iOS simulator via `scripts/snapshot.sh`.
@MainActor
final class WorkoutScreenSnapshotTests: XCTestCase {
    private func content(_ snapshot: WorkoutSnapshot, direction: CountDirection = .countDown,
                         saveFailed: Bool = false) -> some View {
        WorkoutContentView(
            display: WorkoutDisplayModel(snapshot, direction: direction),
            title: "Heavy Bag Blast",
            finishedSummary: "12 rounds · 47:10",
            saveFailed: saveFailed,
            onPlayPause: {}, onReset: {}, onDone: {}, onRetrySave: {}
        )
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

    private func snap(_ phase: WorkoutPhase, remaining: Duration, elapsedInPhase: Duration,
                      elapsedTotal: Duration = .seconds(560), paused: Bool = false,
                      started: Bool = true) -> WorkoutSnapshot {
        WorkoutSnapshot(phase: phase, remaining: remaining, elapsedInPhase: elapsedInPhase,
                        elapsedTotal: elapsedTotal, totalDuration: .seconds(2830), roundCount: 12,
                        isPaused: paused, started: started)
    }

    func test_ready_dark() {
        // Idle/ready: the workout hasn't started, so the primary control shows Play.
        let ready = snap(.preparing, remaining: .seconds(20), elapsedInPhase: .zero,
                         elapsedTotal: .zero, started: false)
        assertScreen(content(ready), style: .dark, name: "ready-dark")
    }
    func test_ready_light() {
        let ready = snap(.preparing, remaining: .seconds(20), elapsedInPhase: .zero,
                         elapsedTotal: .zero, started: false)
        assertScreen(content(ready), style: .light, name: "ready-light")
    }
    func test_round_dark() {
        assertScreen(content(snap(.round(index: 3), remaining: .seconds(83), elapsedInPhase: .seconds(97))),
                     style: .dark, name: "round-dark")
    }
    func test_round_light() {
        assertScreen(content(snap(.round(index: 3), remaining: .seconds(83), elapsedInPhase: .seconds(97))),
                     style: .light, name: "round-light")
    }
    func test_rest_dark() {
        let rest = snap(.resting(afterRound: 3), remaining: .seconds(45), elapsedInPhase: .seconds(15))
        assertScreen(content(rest), style: .dark, name: "rest-dark")
    }
    func test_prepare_dark() {
        let prepare = snap(.preparing, remaining: .seconds(7), elapsedInPhase: .seconds(3),
                           elapsedTotal: .seconds(3))
        assertScreen(content(prepare), style: .dark, name: "prepare-dark")
    }
    func test_paused_dark() {
        let paused = snap(.round(index: 3), remaining: .seconds(83), elapsedInPhase: .seconds(97), paused: true)
        assertScreen(content(paused), style: .dark, name: "paused-dark")
    }
    func test_finished_dark() {
        assertScreen(content(snap(.finished, remaining: .zero, elapsedInPhase: .zero, elapsedTotal: .seconds(2830))),
                     style: .dark, name: "finished-dark")
    }
    func test_finished_saveFailed_dark() {
        let finished = snap(.finished, remaining: .zero, elapsedInPhase: .zero, elapsedTotal: .seconds(2830))
        assertScreen(content(finished, saveFailed: true), style: .dark, name: "finished-save-failed-dark")
    }
}
#endif

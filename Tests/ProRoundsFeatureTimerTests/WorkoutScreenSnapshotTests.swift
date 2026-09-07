#if canImport(UIKit)
import XCTest
import SwiftUI
import SnapshotTesting
@testable import ProRoundsFeatureTimer
import ProRoundsDataConfig
import ProRoundsFoundationUtilities

/// Snapshot tests for the running screen across phases (rendered from a fixed `WorkoutDisplayModel`,
/// so no live engine is involved). iOS simulator via `scripts/snapshot.sh`.
@MainActor
final class WorkoutScreenSnapshotTests: XCTestCase {
    private func content(_ snapshot: WorkoutSnapshot, direction: CountDirection = .countDown,
                         saveFailed: Bool = false, coaching: CoachingLevel? = nil,
                         minimal: Bool = false) -> some View {
        WorkoutContentView(
            display: WorkoutDisplayModel(snapshot, direction: direction, workoutType: .heavyBag,
                                         coachingLevel: coaching, minimalScreen: minimal),
            title: "Heavy Bag Blast",
            finishedSummary: "12 rounds · 47:10",
            saveFailed: saveFailed,
            onPlayPause: {}, onReset: {}, onDone: {}, onRetrySave: {}, onEditCoaching: {}
        )
    }

    private func assertScreen(_ view: some View, style: UIUserInterfaceStyle, name: String,
                              testName: String = #function, line: UInt = #line) {
        withSnapshotTesting(record: snapshotRecordMode) {
            assertSnapshot(
            of: view,
            as: .image(perceptualPrecision: 0.98, layout: .fixed(width: 393, height: 852),
                       traits: UITraitCollection(userInterfaceStyle: style)),
            named: name, testName: testName, line: line
        )
    }
    }

    private func snap(_ phase: WorkoutPhase, remaining: Duration, elapsedInPhase: Duration,
                      elapsedTotal: Duration = .seconds(560), paused: Bool = false,
                      started: Bool = true, call: CoachCallDisplay? = nil) -> WorkoutSnapshot {
        WorkoutSnapshot(phase: phase, remaining: remaining, elapsedInPhase: elapsedInPhase,
                        elapsedTotal: elapsedTotal, totalDuration: .seconds(2830), roundCount: 12,
                        isPaused: paused, started: started, currentCall: call)
    }

    // MARK: - Coached screens
    //
    // New cases rather than edits to the existing ones: those references are the regression guard
    // for the uncoached screen, and folding coaching into them would hide whether it still renders
    // as it did.

    private var punchCall: CoachCallDisplay {
        CoachCallDisplay(primary: "Jab Cross", secondary: "1 · 2", modifier: "to the body")
    }

    func test_coached_round_dark() {
        assertScreen(content(snap(.round(index: 3), remaining: .seconds(95),
                                  elapsedInPhase: .seconds(85), call: punchCall),
                             coaching: .beginner),
                     style: .dark, name: "coached-round-dark")
    }

    func test_coached_round_light() {
        assertScreen(content(snap(.round(index: 3), remaining: .seconds(95),
                                  elapsedInPhase: .seconds(85), call: punchCall),
                             coaching: .beginner),
                     style: .light, name: "coached-round-light")
    }

    /// The chip only appears while idle — changing the level mid-workout would change a round's
    /// plan after it began.
    func test_coached_idle_showsChip_dark() {
        assertScreen(content(snap(.round(index: 1), remaining: .seconds(180),
                                  elapsedInPhase: .zero, started: false),
                             coaching: .beginner),
                     style: .dark, name: "coached-idle-dark")
    }

    /// Everything but the time, the phase and the call is stripped away.
    func test_coached_minimal_dark() {
        assertScreen(content(snap(.round(index: 3), remaining: .seconds(95),
                                  elapsedInPhase: .seconds(85), call: punchCall),
                             coaching: .beginner, minimal: true),
                     style: .dark, name: "coached-minimal-dark")
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

/// How this suite records.
///
/// A **compiler flag**, not an environment variable: `xcodebuild` does not forward an exported
/// variable into the simulator's test process, so `SNAPSHOT_TESTING_RECORD=all` never reached the
/// library and `RECORD=1` silently did nothing but create wholly missing references — which
/// swift-snapshot-testing writes regardless of record mode. Build settings do propagate, so
/// `scripts/snapshot.sh` passes `-D RECORD_SNAPSHOTS`.
///
/// Repeated per target because test modules cannot share a helper without a support target, and one
/// six-line property is cheaper than that.
private var snapshotRecordMode: SnapshotTestingConfiguration.Record {
    #if RECORD_SNAPSHOTS
    return .all
    #else
    return .missing
    #endif
}

#endif

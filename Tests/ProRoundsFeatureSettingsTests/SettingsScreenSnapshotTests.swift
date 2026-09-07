#if canImport(UIKit)
import XCTest
import SwiftUI
import SnapshotTesting
@testable import ProRoundsFeatureSettings
import ProRoundsDataSettings
import ProRoundsFoundationAudio

@MainActor
final class SettingsScreenSnapshotTests: XCTestCase {
    private func settingsView() -> some View {
        let store = InMemorySettingsStore(warningSound: .buzzer, countDirection: .countDown, appearance: .dark)
        return SettingsView(model: SettingsViewModel(store: store, player: SpyAudioCuePlayer()))
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

    func test_settings_dark() { assertScreen(settingsView(), style: .dark, name: "dark") }
    func test_settings_light() { assertScreen(settingsView(), style: .light, name: "light") }
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

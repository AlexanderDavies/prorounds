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
        assertSnapshot(
            of: view,
            as: .image(perceptualPrecision: 0.98, layout: .fixed(width: 393, height: 852),
                       traits: UITraitCollection(userInterfaceStyle: style)),
            named: name, testName: testName, line: line
        )
    }

    func test_settings_dark() { assertScreen(settingsView(), style: .dark, name: "dark") }
    func test_settings_light() { assertScreen(settingsView(), style: .light, name: "light") }
}
#endif

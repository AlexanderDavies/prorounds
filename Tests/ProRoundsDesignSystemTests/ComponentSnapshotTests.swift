#if canImport(UIKit)
import XCTest
import SwiftUI
import SnapshotTesting
@testable import ProRoundsDesignSystem

/// Snapshot tests for every design-system component in light + dark (and a larger Dynamic Type size
/// for text-bearing ones). Rendered on the iOS simulator via `scripts/snapshot.sh`. Reference images
/// are the visual-regression guard — regenerate them only on an intentional design change.
final class ComponentSnapshotTests: XCTestCase {
    private func assertComponent(
        _ view: some View,
        width: CGFloat = 390,
        style: UIUserInterfaceStyle,
        contentSize: UIContentSizeCategory = .large,
        name: String,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        let root = view
            .padding(24)
            .frame(width: width)
            .background(ProRoundsColor.canvas)
        let traits = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: style),
            UITraitCollection(preferredContentSizeCategory: contentSize)
        ])
        withSnapshotTesting(record: snapshotRecordMode) {
            assertSnapshot(
            of: root,
            as: .image(perceptualPrecision: 0.98, layout: .sizeThatFits, traits: traits),
            named: name,
            file: file,
            testName: testName,
            line: line
        )
    }
    }

    // MARK: Buttons

    private var buttonGallery: some View {
        VStack(spacing: Spacing.md) {
            Button("Start") {}.buttonStyle(.proPrimary)
            Button("Edit") {}.buttonStyle(.proSecondary)
            Button("Add new") {}.buttonStyle(.proTertiary)
            Button("Delete") {}.buttonStyle(.proDestructive)
        }
    }

    func test_buttons_light() { assertComponent(buttonGallery, style: .light, name: "light") }
    func test_buttons_dark() { assertComponent(buttonGallery, style: .dark, name: "dark") }
    func test_buttons_dynamicType() {
        assertComponent(buttonGallery, style: .dark, contentSize: .accessibilityLarge, name: "axLarge")
    }

    // MARK: PhaseBadge

    private var phaseBadgeGallery: some View {
        VStack(spacing: Spacing.sm) {
            PhaseBadge(label: "Prepare", color: ProRoundsColor.phasePrepare)
            PhaseBadge(label: "Round 3 / 12", color: ProRoundsColor.phaseRound)
            PhaseBadge(label: "Rest", color: ProRoundsColor.phaseRest)
            PhaseBadge(label: "Done", color: ProRoundsColor.phaseFinished)
        }
    }

    func test_phaseBadge_light() { assertComponent(phaseBadgeGallery, style: .light, name: "light") }
    func test_phaseBadge_dark() { assertComponent(phaseBadgeGallery, style: .dark, name: "dark") }
    func test_phaseBadge_dynamicType() {
        assertComponent(phaseBadgeGallery, style: .dark, contentSize: .accessibilityLarge, name: "axLarge")
    }

    // MARK: TimerRing

    private func timerRing(_ color: ThemeColor, label: String, numeral: String) -> some View {
        TimerRing(progress: 0.62, phaseColor: color, badgeLabel: label,
                  numeral: numeral, totalRemaining: "12:40 left", diameter: 300)
    }

    func test_timerRing_round_light() {
        assertComponent(timerRing(ProRoundsColor.phaseRound, label: "Round 3 / 12", numeral: "01:23"),
                        style: .light, name: "round-light")
    }
    func test_timerRing_round_dark() {
        assertComponent(timerRing(ProRoundsColor.phaseRound, label: "Round 3 / 12", numeral: "01:23"),
                        style: .dark, name: "round-dark")
    }
    func test_timerRing_rest_dark() {
        assertComponent(timerRing(ProRoundsColor.phaseRest, label: "Rest", numeral: "00:18"),
                        style: .dark, name: "rest-dark")
    }

    // MARK: TransportControls

    private var transportGallery: some View {
        VStack(spacing: Spacing.xl) {
            TransportControls(isRunning: false, isResetEnabled: false, onPlayPause: {}, onReset: {})
            TransportControls(isRunning: true, isResetEnabled: true, onPlayPause: {}, onReset: {})
        }
    }

    func test_transport_light() { assertComponent(transportGallery, style: .light, name: "light") }
    func test_transport_dark() { assertComponent(transportGallery, style: .dark, name: "dark") }

    // MARK: ConfigCard

    private var configCardGallery: some View {
        VStack(spacing: Spacing.md) {
            ConfigCard(iconSystemName: "figure.boxing", name: "Heavy Bag Blast",
                       metadata: "12 × 3:00 · 1:00 rest", totalText: "47:10")
            ConfigCard(iconSystemName: "figure.jumprope", name: "Quick Shadow",
                       metadata: "3 × 2:00 · 0:30 rest", totalText: "7:00")
        }
    }

    func test_configCard_light() { assertComponent(configCardGallery, style: .light, name: "light") }
    func test_configCard_dark() { assertComponent(configCardGallery, style: .dark, name: "dark") }
    func test_configCard_dynamicType() {
        assertComponent(configCardGallery, style: .dark, contentSize: .accessibilityLarge, name: "axLarge")
    }

    // MARK: ConfigCard — coached
    //
    // Its own gallery rather than a change to the one above: the existing references are the
    // regression guard for the uncoached card, and a badge appearing in them would hide whether the
    // default layout still holds.

    private var coachedCardGallery: some View {
        VStack(spacing: Spacing.md) {
            ConfigCard(iconSystemName: "figure.boxing", name: "Heavy Bag Blast",
                       metadata: "12 × 3:00 · 1:00 rest", totalText: "47:10",
                       coachingBadge: "Beginner")
            ConfigCard(iconSystemName: "figure.boxing", name: "Uncoached, for comparison",
                       metadata: "12 × 3:00 · 1:00 rest", totalText: "47:10")
        }
    }

    func test_coachedCard_light() { assertComponent(coachedCardGallery, style: .light, name: "light") }
    func test_coachedCard_dark() { assertComponent(coachedCardGallery, style: .dark, name: "dark") }
    func test_coachedCard_dynamicType() {
        assertComponent(coachedCardGallery, style: .dark, contentSize: .accessibilityLarge, name: "axLarge")
    }

    // MARK: Coach ticker

    private var coachTickerGallery: some View {
        VStack(spacing: Spacing.xl) {
            CoachTickerView(primary: "Jab Cross", secondary: "1 · 2", modifier: "to the body",
                            accessibleDescription: "Jab Cross, to the body")
            CoachTickerView(primary: "Circle left", secondary: nil, modifier: nil,
                            accessibleDescription: "Circle left")
            CoachTickerView(primary: "Jab Cross Hook", secondary: "1 · 2 · 3", modifier: nil,
                            accessibleDescription: "Jab Cross Hook")
        }
    }

    func test_coachTicker_light() { assertComponent(coachTickerGallery, style: .light, name: "light") }
    func test_coachTicker_dark() { assertComponent(coachTickerGallery, style: .dark, name: "dark") }
    /// The ticker is the whole channel for a user who cannot hear the coach, so it has to survive
    /// the largest accessibility sizes rather than truncating to nothing.
    func test_coachTicker_dynamicType() {
        assertComponent(coachTickerGallery, style: .dark, contentSize: .accessibilityLarge, name: "axLarge")
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

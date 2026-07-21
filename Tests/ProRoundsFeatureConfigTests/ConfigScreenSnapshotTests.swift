#if canImport(UIKit)
import XCTest
import SwiftUI
import SnapshotTesting
@testable import ProRoundsFeatureConfig
import ProRoundsDataConfig

/// Snapshot tests for the config screens (populated list, empty list, editor) in light + dark on the
/// iOS simulator. Rendered via `scripts/snapshot.sh`; reference images are the regression guard.
@MainActor
final class ConfigScreenSnapshotTests: XCTestCase {
    private func assertScreen(
        _ view: some View,
        style: UIUserInterfaceStyle,
        name: String,
        testName: String = #function,
        line: UInt = #line
    ) {
        assertSnapshot(
            of: view,
            as: .image(
                perceptualPrecision: 0.98,
                layout: .fixed(width: 393, height: 852),
                traits: UITraitCollection(userInterfaceStyle: style)
            ),
            named: name,
            testName: testName,
            line: line
        )
    }

    private func seededListView(empty: Bool) async throws -> some View {
        let repo = try ConfigTestSupport.makeRepository()
        if !empty {
            try await repo.save(ConfigTestSupport.config("Heavy Bag Blast"))
            try await repo.save(ConfigTestSupport.config(nil, type: .skipping, rounds: 3,
                                                         round: .seconds(120), rest: .seconds(30)))
        }
        let model = ConfigListViewModel(repository: repo)
        await model.load()
        return NavigationStack {
            ConfigListView(model: model,
                           makeEditor: { ConfigEditorViewModel(editing: $0, repository: repo) },
                           onStartWorkout: { _ in })
        }
    }

    func test_list_populated_light() async throws {
        assertScreen(try await seededListView(empty: false), style: .light, name: "light")
    }
    func test_list_populated_dark() async throws {
        assertScreen(try await seededListView(empty: false), style: .dark, name: "dark")
    }
    func test_list_empty_dark() async throws {
        assertScreen(try await seededListView(empty: true), style: .dark, name: "empty-dark")
    }

    func test_editor_dark() async throws {
        let repo = try ConfigTestSupport.makeRepository()
        let model = ConfigEditorViewModel(editing: ConfigTestSupport.config("Heavy Bag Blast"), repository: repo)
        assertScreen(ConfigEditorView(model: model, onDone: {}), style: .dark, name: "dark")
    }

    func test_editor_newBlankName_dark() async throws {
        // Create mode: the name is blank, so the field shows the auto-name as its placeholder.
        let repo = try ConfigTestSupport.makeRepository()
        let model = ConfigEditorViewModel(editing: nil, repository: repo)
        assertScreen(ConfigEditorView(model: model, onDone: {}), style: .dark, name: "new-blank-name-dark")
    }
}
#endif

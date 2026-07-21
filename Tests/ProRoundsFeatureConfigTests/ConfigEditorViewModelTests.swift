import Testing
import Foundation
@testable import ProRoundsFeatureConfig
import ProRoundsDataConfig

@MainActor
@Suite("ConfigEditorViewModel")
struct ConfigEditorViewModelTests {
    @Test("Live total and auto-name recompute as the draft changes")
    func livePreview() async throws {
        let model = ConfigEditorViewModel(editing: nil, repository: try ConfigTestSupport.makeRepository())
        model.draft.workoutType = .heavyBag
        model.draft.rounds = 12
        model.draft.roundSeconds = 180
        model.draft.restSeconds = 60
        model.draft.prepSeconds = 10
        model.draft.name = ""

        #expect(model.totalText == "47:00") // rounds + rest, prep excluded
        // Blank name → the field's placeholder is the live auto-name.
        #expect(model.autoName == "Heavy Bag · 12×3min / 1min rest")

        model.draft.rounds = 3
        #expect(model.totalText == "11:00") // 3×180 + 2×60 = 660s (prep excluded)
        #expect(model.autoName == "Heavy Bag · 3×3min / 1min rest") // auto-name recomputes live
    }

    @Test("Typing sets the custom name; clearing reverts to the auto-name")
    func nameFieldSetsAndReverts() async throws {
        let model = ConfigEditorViewModel(editing: nil, repository: try ConfigTestSupport.makeRepository())
        let auto = model.autoName

        model.draft.name = "Sparring Day"
        #expect(model.draft.effectiveName == "Sparring Day")

        model.draft.name = "" // cleared → back to the auto-name (placeholder)
        #expect(model.draft.effectiveName == auto)
    }

    @Test("Saving invalid input surfaces errors and persists nothing")
    func saveInvalid() async throws {
        let repo = try ConfigTestSupport.makeRepository()
        let model = ConfigEditorViewModel(editing: nil, repository: repo)
        model.draft.roundSeconds = 60
        model.draft.warningLeadSeconds = 60 // lead == round → invalid

        let saved = await model.save()
        #expect(saved == false)
        #expect(model.errors.contains(.warningLeadOutOfRange))
        #expect(try await repo.all().isEmpty)
    }

    @Test("Saving valid input persists a new configuration")
    func saveValidInsert() async throws {
        let repo = try ConfigTestSupport.makeRepository()
        let model = ConfigEditorViewModel(editing: nil, repository: repo)
        model.draft.name = "My Workout"
        model.draft.warningLeadSeconds = 10
        model.draft.roundSeconds = 180

        let saved = await model.save()
        #expect(saved)
        let all = try await repo.all()
        #expect(all.count == 1)
        #expect(all.first?.customName == "My Workout")
    }

    @Test("Editing an existing configuration updates it in place")
    func saveValidUpdate() async throws {
        let repo = try ConfigTestSupport.makeRepository()
        let original = ConfigTestSupport.config("Original", rounds: 5)
        try await repo.save(original)

        let model = ConfigEditorViewModel(editing: original, repository: repo)
        #expect(model.isEditing)
        model.draft.name = "Renamed"
        model.draft.rounds = 9

        #expect(await model.save())
        let all = try await repo.all()
        #expect(all.count == 1)
        #expect(all.first?.customName == "Renamed")
        #expect(all.first?.rounds == 9)
        #expect(all.first?.id == original.id)
    }

    @Test("Delete removes the edited configuration")
    func delete() async throws {
        let repo = try ConfigTestSupport.makeRepository()
        let target = ConfigTestSupport.config("Doomed")
        try await repo.save(target)

        let model = ConfigEditorViewModel(editing: target, repository: repo)
        await model.delete()
        #expect(try await repo.all().isEmpty)
    }
}

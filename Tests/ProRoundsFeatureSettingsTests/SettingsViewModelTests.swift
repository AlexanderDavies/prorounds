import Testing
@testable import ProRoundsFeatureSettings
import ProRoundsDataSettings
import ProRoundsFoundationAudio
import ProRoundsFoundationUtilities

@MainActor
@Suite("SettingsViewModel")
struct SettingsViewModelTests {
    private struct Harness {
        let model: SettingsViewModel
        let store: InMemorySettingsStore
        let spy: SpyAudioCuePlayer
    }

    private func make() -> Harness {
        let store = InMemorySettingsStore()
        let spy = SpyAudioCuePlayer()
        return Harness(model: SettingsViewModel(store: store, player: spy), store: store, spy: spy)
    }

    @Test("Initialises from the store")
    func initialisesFromStore() {
        let store = InMemorySettingsStore(warningSound: .buzzer, countDirection: .countUp, appearance: .dark)
        let model = SettingsViewModel(store: store, player: SpyAudioCuePlayer())
        #expect(model.warningSound == .buzzer)
        #expect(model.countDirection == .countUp)
        #expect(model.appearance == .dark)
    }

    @Test("Selecting a warning sound persists it and plays a preview")
    func selectWarningSoundPreviews() async {
        let harness = make()
        harness.model.selectWarningSound(.electronicHorn)

        #expect(harness.model.warningSound == .electronicHorn)
        #expect(harness.store.warningSound == .electronicHorn)

        var iterations = 0
        while await harness.spy.played.isEmpty, iterations < 100_000 { await Task.yield(); iterations += 1 }
        #expect(await harness.spy.played.contains(.roundEndWarning(.electronicHorn)))
    }

    @Test("Setting count direction and appearance persists them")
    func setsAndPersists() {
        let harness = make()
        harness.model.setCountDirection(.countUp)
        harness.model.setAppearance(.light)
        #expect(harness.store.countDirection == .countUp)
        #expect(harness.store.appearance == .light)
        #expect(harness.model.countDirection == .countUp)
        #expect(harness.model.appearance == .light)
    }
}

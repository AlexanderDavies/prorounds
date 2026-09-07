import Testing
import Foundation
import ProRoundsDataSettings
import ProRoundsFoundationAudio
import ProRoundsFoundationCoaching
@testable import ProRoundsFeatureSettings

@Suite("Coaching rows in Settings")
@MainActor
struct CoachingSettingsTests {
    private func make() -> (SettingsViewModel, InMemorySettingsStore) {
        let store = InMemorySettingsStore()
        return (SettingsViewModel(store: store, player: SpyAudioCuePlayer()), store)
    }

    @Test("the view model initialises from the store")
    func initialisesFromStore() {
        let store = InMemorySettingsStore(namingConvention: .names, minimalRunningScreen: true)
        let model = SettingsViewModel(store: store, player: SpyAudioCuePlayer())
        #expect(model.namingConvention == .names)
        #expect(model.minimalRunningScreen)
    }

    @Test("changing the convention writes through to the store")
    func conventionWritesThrough() {
        let (model, store) = make()
        model.setNamingConvention(.names)
        #expect(model.namingConvention == .names)
        #expect(store.namingConvention == .names)
    }

    @Test("toggling the minimal screen writes through to the store")
    func minimalWritesThrough() {
        let (model, store) = make()
        model.setMinimalRunningScreen(true)
        #expect(model.minimalRunningScreen)
        #expect(store.minimalRunningScreen)
    }

    /// Someone who does not yet know the numbering cannot choose between "Numbers" and "Names"
    /// without hearing what each means, so each option carries an example of the coach's words.
    @Test("each convention is offered with an example of what the coach says")
    func conventionsCarryExamples() {
        #expect(NamingConvention.numbers.example == "One, two")
        #expect(NamingConvention.names.example == "Jab, cross")
        for convention in NamingConvention.allCases {
            #expect(convention.displayName != convention.example)
        }
    }

    @Test("coaching rows do not disturb the existing preferences")
    func existingPreferencesUnaffected() {
        let (model, store) = make()
        model.setNamingConvention(.names)
        model.setMinimalRunningScreen(true)
        #expect(store.countDirection == .countDown)
        #expect(store.appearance == .system)
        #expect(model.appearance == .system)
    }
}

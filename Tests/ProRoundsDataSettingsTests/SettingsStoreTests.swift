import Testing
import Foundation
@testable import ProRoundsDataSettings
import ProRoundsFoundationAudio
import ProRoundsFoundationUtilities

@Suite("SettingsStore")
struct SettingsStoreTests {
    @Test("Fresh UserDefaults store returns defaults")
    func defaults() throws {
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = UserDefaultsSettingsStore(defaults: defaults)
        #expect(store.countDirection == .countDown)
        #expect(store.appearance == .system)
        #expect(store.warningSound == .woodenClap)
    }

    @Test("A changed preference is durable across store instances")
    func durable() throws {
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        UserDefaultsSettingsStore(defaults: defaults).appearance = .dark
        #expect(UserDefaultsSettingsStore(defaults: defaults).appearance == .dark)
    }

    @Test("In-memory fake round-trips without UserDefaults")
    func fake() {
        let store = InMemorySettingsStore()
        store.countDirection = .countUp
        store.warningSound = .buzzer
        store.appearance = .light
        #expect(store.countDirection == .countUp)
        #expect(store.warningSound == .buzzer)
        #expect(store.appearance == .light)
    }
}

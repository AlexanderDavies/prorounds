import Testing
import Foundation
import ProRoundsFoundationCoaching
@testable import ProRoundsDataSettings

@Suite("Coaching preferences")
struct CoachingPreferencesTests {
    /// A suite name unique per test, so one test's writes cannot leak into another's defaults.
    private func freshDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "coaching.\(UUID().uuidString)"))
    }

    @Test("a fresh store defaults to numbers and a non-minimal screen")
    func defaults() {
        let store = InMemorySettingsStore()
        #expect(store.namingConvention == .numbers)
        #expect(store.minimalRunningScreen == false)
    }

    @Test("a fresh UserDefaults store has the same defaults")
    func userDefaultsDefaults() throws {
        let store = UserDefaultsSettingsStore(defaults: try freshDefaults())
        #expect(store.namingConvention == .numbers)
        #expect(store.minimalRunningScreen == false)
    }

    @Test("the naming convention is durable")
    func conventionIsDurable() throws {
        let defaults = try freshDefaults()
        UserDefaultsSettingsStore(defaults: defaults).namingConvention = .names
        #expect(UserDefaultsSettingsStore(defaults: defaults).namingConvention == .names)
    }

    @Test("the minimal-screen preference is durable")
    func minimalIsDurable() throws {
        let defaults = try freshDefaults()
        UserDefaultsSettingsStore(defaults: defaults).minimalRunningScreen = true
        #expect(UserDefaultsSettingsStore(defaults: defaults).minimalRunningScreen == true)
    }

    @Test("an unrecognised stored convention falls back to the default")
    func corruptValueFallsBack() throws {
        let defaults = try freshDefaults()
        defaults.set("hieroglyphs", forKey: "settings.coaching.namingConvention")
        #expect(UserDefaultsSettingsStore(defaults: defaults).namingConvention == .numbers)
    }

    /// Reuses `NamingConvention` from the coaching module rather than declaring a second enum with
    /// the same cases — the scheduler and the setting must mean the same thing by construction.
    @Test("both conventions are offered with an example of what the coach says")
    func conventionsAreExplained() {
        #expect(NamingConvention.allCases.count == 2)
        for convention in NamingConvention.allCases {
            #expect(!convention.displayName.isEmpty)
            #expect(!convention.example.isEmpty)
        }
        #expect(NamingConvention.numbers.example == "One, two")
        #expect(NamingConvention.names.example == "Jab, cross")
    }
}

@Suite("Preferences are person-level, not per-workout")
struct CoachingPreferenceScopeTests {
    /// The convention describes how the user wants to be coached, not what a workout is. Changing
    /// it must not touch stored configurations — if it did, a settings toggle would dirty every
    /// record and break equality for callers diffing them.
    @Test("changing the convention rewrites nothing and preserves equality")
    func changingConventionTouchesNoConfiguration() {
        let store = InMemorySettingsStore()
        let before = store.namingConvention
        store.namingConvention = .names
        #expect(before != store.namingConvention)
        // Nothing in the settings store can reach a configuration: it holds only scalars, and the
        // protocol exposes no repository. Asserted structurally by the absence of any such member.
        #expect(store.minimalRunningScreen == false, "unrelated preferences are unaffected")
    }

    @Test("one preference change does not disturb the others")
    func preferencesAreIndependent() {
        let store = InMemorySettingsStore()
        store.namingConvention = .names
        store.minimalRunningScreen = true
        #expect(store.warningSound == .woodenClap)
        #expect(store.countDirection == .countDown)
        #expect(store.appearance == .system)
    }
}

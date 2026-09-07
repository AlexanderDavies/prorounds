import Foundation
import SwiftData
import ProRoundsDataConfig
import ProRoundsDataSessions
import ProRoundsDataSettings
import ProRoundsFoundationCoaching
import ProRoundsFoundationAudio
import ProRoundsFoundationPersistence
import ProRoundsFoundationTiming
import ProRoundsFoundationUtilities

/// The composition root's dependency container (guide §5.3). Builds the on-disk SwiftData store, the
/// repository, and the workout seams (clock, audio player, interruption monitor, idle timer) **once**,
/// here; everything downstream receives them by injection.
@MainActor
final class AppEnvironment {
    let configurationRepository: any ConfigurationRepository
    let sessionRepository: any SessionRepository
    let settingsStore: any SettingsStore
    let timeSource: any TimeSource
    let audioPlayer: any AudioCuePlayer
    let interruptions: any AudioInterruptionMonitoring
    let idleTimer: AppIdleTimer
    /// Whether coaching is unlocked. Constructed here and injected like every other dependency, so
    /// landing a paywall later is a change to this file rather than a refactor across features.
    let entitlementStore: any EntitlementStore

    init() {
        // One shared on-disk store for configurations + sessions.
        let models = ConfigurationStore.models + SessionStore.models
        // UI tests launch with an in-memory store seeded with a known configuration (hermetic).
        let uiTestSeed = ProcessInfo.processInfo.arguments.contains("-uiTestSeed")
        let container: ModelContainer
        if uiTestSeed, let memory = try? PersistenceContainer.make(for: models, inMemory: true) {
            container = memory
            ConfigurationStore.seed([Self.demoConfiguration], into: container)
        } else if let onDisk = try? PersistenceContainer.make(for: models, inMemory: false) {
            container = onDisk
        } else if let memory = try? PersistenceContainer.make(for: models, inMemory: true) {
            container = memory
        } else {
            fatalError("ProRounds could not create its persistence store.")
        }
        configurationRepository = SwiftDataConfigurationRepository(modelContainer: container)
        sessionRepository = SwiftDataSessionRepository(modelContainer: container)
        settingsStore = UserDefaultsSettingsStore()
        timeSource = RealTimeSource()
        audioPlayer = AVAudioCuePlayer()
        interruptions = SystemAudioInterruptionMonitor()
        // v1 ships everything unlocked; the seam exists so that stops being true without a refactor.
        entitlementStore = UnlockedEntitlementStore()
        idleTimer = AppIdleTimer()
    }

    private static let demoConfiguration = Configuration(
        workoutType: .heavyBag, rounds: 3, roundDuration: .seconds(120),
        restDuration: .seconds(30), prepDuration: .seconds(5), warningLead: .seconds(10),
        customName: "UI Test Bag",
        // Coached, so the UI flow test exercises the whole path: a real catalog load, a real
        // schedule, real clips resolved from the bundle, and the ticker on a real clock.
        coachingLevel: .beginner
    )
}

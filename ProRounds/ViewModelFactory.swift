import Foundation
import ProRoundsDataConfig
import ProRoundsFeatureConfig
import ProRoundsFeaturePerformance
import ProRoundsFeatureTimer
import ProRoundsFoundationAudio
import ProRoundsFoundationCoaching

/// Turns the app environment into ready-wired view models (guide §5.3), so views never assemble
/// their own collaborators.
@MainActor
struct ViewModelFactory {
    let environment: AppEnvironment

    func configList() -> ConfigListViewModel {
        ConfigListViewModel(repository: environment.configurationRepository)
    }

    func configEditor(_ configuration: Configuration?) -> ConfigEditorViewModel {
        ConfigEditorViewModel(editing: configuration, repository: environment.configurationRepository)
    }

    func performance() -> PerformanceViewModel {
        PerformanceViewModel(sessions: environment.sessionRepository)
    }

    func workout(_ configuration: Configuration) -> WorkoutViewModel {
        // Read the current preferences so a settings change applies to the next workout.
        let store = environment.settingsStore
        let engine = RoundTimerEngine(
            configuration: configuration,
            timeSource: environment.timeSource,
            player: environment.audioPlayer,
            warningSound: store.warningSound,
            cuePlanner: coachPlanner(for: configuration)
        )
        return WorkoutViewModel(
            configuration: configuration,
            engine: engine,
            idleTimer: environment.idleTimer,
            interruptions: environment.interruptions,
            sessions: environment.sessionRepository,
            countDirection: store.countDirection,
            configurationWriter: RepositoryConfigurationWriter(
                repository: environment.configurationRepository),
            minimalScreen: store.minimalRunningScreen,
            conventionOptions: conventionOptions(selected: store.namingConvention),
            onSelectConvention: { identifier in
                guard let convention = NamingConvention(rawValue: identifier) else { return }
                store.namingConvention = convention
            }
        )
    }

    /// Builds the coaching planner, or one that plans nothing.
    ///
    /// This is the only place the catalog, the preferences and the entitlement meet — the timer
    /// module cannot name any of them. A catalog that fails to load degrades to no coaching rather
    /// than propagating: a content problem must never cost the user their timer.
    private func coachPlanner(for configuration: Configuration) -> any RoundCuePlanning {
        guard let level = configuration.coachingLevel else { return NoRoundCuePlanner() }
        _ = level  // Beginner is the only level in v1; it selects no variant yet.
        let warningMs = Int(configuration.warningLead.components.seconds) * 1000
        return CoachCuePlanner.makeOrSilent(
            workoutType: configuration.workoutType,
            configID: configuration.id.uuidString,
            convention: environment.settingsStore.namingConvention,
            warningMs: warningMs,
            entitlement: environment.entitlementStore)
    }

    /// The naming-convention choices, resolved to strings because `ProRoundsFeatureTimer` cannot
    /// name the convention type — that is what keeps it unable to reach the entitlement.
    private func conventionOptions(selected: NamingConvention) -> [CoachingConventionOption] {
        NamingConvention.allCases.map { convention in
            CoachingConventionOption(
                id: convention.rawValue,
                label: "\(convention.displayName) — \u{201C}\(convention.example)\u{201D}",
                isSelected: convention == selected)
        }
    }
}

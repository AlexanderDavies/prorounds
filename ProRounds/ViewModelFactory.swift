import Foundation
import ProRoundsDataConfig
import ProRoundsFeatureConfig
import ProRoundsFeaturePerformance
import ProRoundsFeatureTimer

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
        let engine = RoundTimerEngine(
            configuration: configuration,
            timeSource: environment.timeSource,
            player: environment.audioPlayer,
            warningSound: environment.settingsStore.warningSound
        )
        return WorkoutViewModel(
            configuration: configuration,
            engine: engine,
            idleTimer: environment.idleTimer,
            interruptions: environment.interruptions,
            sessions: environment.sessionRepository,
            countDirection: environment.settingsStore.countDirection
        )
    }
}

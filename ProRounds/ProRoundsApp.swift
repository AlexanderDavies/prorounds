import SwiftUI
import ProRoundsFeatureSettings

/// App entry point and composition root. Builds the object graph once and injects it down: the
/// `ViewModelFactory` for feature view models, and a single shared `SettingsViewModel` that both
/// drives the app's appearance and backs the Settings tab.
@main
struct ProRoundsApp: App {
    private let factory: ViewModelFactory
    @State private var settings: SettingsViewModel

    init() {
        let environment = AppEnvironment()
        factory = ViewModelFactory(environment: environment)
        _settings = State(initialValue: SettingsViewModel(store: environment.settingsStore,
                                                           player: environment.audioPlayer))
    }

    var body: some Scene {
        WindowGroup {
            RootView(factory: factory, settings: settings)
        }
    }
}

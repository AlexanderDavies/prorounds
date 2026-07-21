import SwiftUI
import ProRoundsDataConfig
import ProRoundsFeatureConfig
import ProRoundsFeaturePerformance
import ProRoundsFeatureSettings
import ProRoundsFeatureTimer

/// The root three-tab shell (Timer · Performance · Settings): the config list, the chart, and the
/// settings screen. The chosen appearance drives `preferredColorScheme` app-wide.
///
/// The app owns the workout navigation (a card tap pushes the running screen) because the config
/// feature cannot import the timer feature — the list just reports which configuration to start.
struct RootView: View {
    let factory: ViewModelFactory
    let settings: SettingsViewModel
    @State private var selectedTab: Tab = .timer
    @State private var workoutPath: [Configuration] = []

    private enum Tab { case timer, performance, settings }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $workoutPath) {
                ConfigListView(
                    model: factory.configList(),
                    makeEditor: { factory.configEditor($0) },
                    onStartWorkout: { workoutPath.append($0) }
                )
                .navigationDestination(for: Configuration.self) { configuration in
                    WorkoutView(model: factory.workout(configuration))
                }
            }
            .tabItem { Label("Timer", systemImage: "timer") }
            .tag(Tab.timer)

            PerformanceView(model: factory.performance())
                .tabItem { Label("Performance", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(Tab.performance)

            SettingsView(model: settings)
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
        .preferredColorScheme(settings.appearance.colorScheme)
        // Switching tabs abandons any in-progress workout and returns the Timer tab to its root (the
        // configuration list) — so re-selecting Timer opens home, not a stale, half-torn-down workout.
        .onChange(of: selectedTab) { _, _ in workoutPath.removeAll() }
    }
}

#Preview {
    let environment = AppEnvironment()
    return RootView(
        factory: ViewModelFactory(environment: environment),
        settings: SettingsViewModel(store: environment.settingsStore, player: environment.audioPlayer)
    )
}

import Foundation
import Observation
import ProRoundsDataSettings
import ProRoundsFoundationAudio
import ProRoundsFoundationUtilities

/// The shared, observable source of the app's preferences (guide §3.2). Mirrors the `SettingsStore`
/// and writes through on change; the app root observes `appearance` to drive `preferredColorScheme`.
@MainActor
@Observable
public final class SettingsViewModel {
    public private(set) var warningSound: WarningSound
    public private(set) var countDirection: CountDirection
    public private(set) var appearance: ColorSchemePreference

    private let store: any SettingsStore
    private let player: any AudioCuePlayer

    public init(store: any SettingsStore, player: any AudioCuePlayer) {
        self.store = store
        self.player = player
        self.warningSound = store.warningSound
        self.countDirection = store.countDirection
        self.appearance = store.appearance
    }

    /// Selects a warning sound, persists it, and plays a preview.
    public func selectWarningSound(_ sound: WarningSound) {
        warningSound = sound
        store.warningSound = sound
        Task { [player] in
            await player.prepare()
            await player.play(.roundEndWarning(sound))
        }
    }

    public func setCountDirection(_ direction: CountDirection) {
        countDirection = direction
        store.countDirection = direction
    }

    public func setAppearance(_ preference: ColorSchemePreference) {
        appearance = preference
        store.appearance = preference
    }
}

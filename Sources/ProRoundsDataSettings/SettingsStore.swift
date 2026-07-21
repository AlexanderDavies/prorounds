import Foundation
import ProRoundsFoundationAudio
import ProRoundsFoundationUtilities

/// How the app resolves its color scheme (DESIGN §7.5). A plain enum — the app maps it to SwiftUI's
/// `ColorScheme?` (system → nil).
public enum ColorSchemePreference: String, CaseIterable, Codable, Sendable, Equatable {
    case light, dark, system
}

/// The store for non-sensitive preferences (guide §6.4). Small, synchronous, injected — features
/// never read `UserDefaults` directly. Class-bound so a held reference is mutated in place.
public protocol SettingsStore: AnyObject, Sendable {
    var warningSound: WarningSound { get set }
    var countDirection: CountDirection { get set }
    var appearance: ColorSchemePreference { get set }
}

/// `UserDefaults`-backed store. Thread-safe via `UserDefaults`; accessed on the main actor in practice.
public final class UserDefaultsSettingsStore: SettingsStore, @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private enum Key {
        static let warningSound = "settings.warningSound"
        static let countDirection = "settings.countDirection"
        static let appearance = "settings.appearance"
    }

    public var warningSound: WarningSound {
        get { defaults.string(forKey: Key.warningSound).flatMap(WarningSound.init(rawValue:)) ?? .woodenClap }
        set { defaults.set(newValue.rawValue, forKey: Key.warningSound) }
    }

    public var countDirection: CountDirection {
        get { defaults.string(forKey: Key.countDirection).flatMap(CountDirection.init(rawValue:)) ?? .countDown }
        set { defaults.set(newValue.rawValue, forKey: Key.countDirection) }
    }

    public var appearance: ColorSchemePreference {
        get { defaults.string(forKey: Key.appearance).flatMap(ColorSchemePreference.init(rawValue:)) ?? .system }
        set { defaults.set(newValue.rawValue, forKey: Key.appearance) }
    }
}

/// In-memory store for tests — no `UserDefaults`, no disk.
public final class InMemorySettingsStore: SettingsStore, @unchecked Sendable {
    public var warningSound: WarningSound
    public var countDirection: CountDirection
    public var appearance: ColorSchemePreference

    public init(
        warningSound: WarningSound = .woodenClap,
        countDirection: CountDirection = .countDown,
        appearance: ColorSchemePreference = .system
    ) {
        self.warningSound = warningSound
        self.countDirection = countDirection
        self.appearance = appearance
    }
}

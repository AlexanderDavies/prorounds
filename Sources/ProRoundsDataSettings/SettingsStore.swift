import Foundation
import ProRoundsFoundationAudio
import ProRoundsFoundationCoaching
import ProRoundsFoundationUtilities

/// How the app resolves its color scheme (DESIGN §7.5). A plain enum — the app maps it to SwiftUI's
/// `ColorScheme?` (system → nil).
public enum ColorSchemePreference: String, CaseIterable, Codable, Sendable, Equatable {
    case light, dark, system
}

public extension NamingConvention {
    /// Reused from the coaching module rather than redeclared here: the setting and the scheduler
    /// must mean the same thing by construction, not by two enums agreeing.
    var displayName: String {
        switch self {
        case .numbers: return "Numbers"
        case .names: return "Names"
        }
    }

    /// What the coach actually says, so the choice is legible to someone who does not yet know the
    /// numbering. Mirrors the `jab_cross` phrase in the catalog.
    var example: String {
        switch self {
        case .numbers: return "One, two"
        case .names: return "Jab, cross"
        }
    }
}

/// The store for non-sensitive preferences (guide §6.4). Small, synchronous, injected — features
/// never read `UserDefaults` directly. Class-bound so a held reference is mutated in place.
public protocol SettingsStore: AnyObject, Sendable {
    var warningSound: WarningSound { get set }
    var countDirection: CountDirection { get set }
    var appearance: ColorSchemePreference { get set }
    /// How the coach names punches. A preference about the person, not about a workout — nobody
    /// flips it per configuration, so it does not live on `Configuration`.
    var namingConvention: NamingConvention { get set }
    /// Whether the running screen hides everything but the essentials during a coached round.
    var minimalRunningScreen: Bool { get set }
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
        static let namingConvention = "settings.coaching.namingConvention"
        static let minimalRunningScreen = "settings.coaching.minimalRunningScreen"
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

    public var namingConvention: NamingConvention {
        get { defaults.string(forKey: Key.namingConvention).flatMap(NamingConvention.init(rawValue:)) ?? .numbers }
        set { defaults.set(newValue.rawValue, forKey: Key.namingConvention) }
    }

    public var minimalRunningScreen: Bool {
        get { defaults.bool(forKey: Key.minimalRunningScreen) }
        set { defaults.set(newValue, forKey: Key.minimalRunningScreen) }
    }
}

/// In-memory store for tests — no `UserDefaults`, no disk.
public final class InMemorySettingsStore: SettingsStore, @unchecked Sendable {
    public var warningSound: WarningSound
    public var countDirection: CountDirection
    public var appearance: ColorSchemePreference
    public var namingConvention: NamingConvention
    public var minimalRunningScreen: Bool

    public init(
        warningSound: WarningSound = .woodenClap,
        countDirection: CountDirection = .countDown,
        appearance: ColorSchemePreference = .system,
        namingConvention: NamingConvention = .numbers,
        minimalRunningScreen: Bool = false
    ) {
        self.warningSound = warningSound
        self.countDirection = countDirection
        self.appearance = appearance
        self.namingConvention = namingConvention
        self.minimalRunningScreen = minimalRunningScreen
    }
}

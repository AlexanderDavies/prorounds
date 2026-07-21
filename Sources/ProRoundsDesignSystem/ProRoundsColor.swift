import SwiftUI
import ProRoundsFoundationUtilities

/// The semantic color roles from `DESIGN.md` §3.2 (light / dark). Features and components reference
/// these — never a raw hex. `DESIGN.md` is the source of truth for the values.
public enum ProRoundsColor {
    // Surfaces & structure
    public static let canvas = ThemeColor(light: Color(hex: 0xF7F7F8), dark: Color(hex: 0x0A0A0B))
    public static let surfaceBase = ThemeColor(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x0A0A0B))
    public static let surfaceRaised = ThemeColor(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x141416))
    public static let surfaceOverlay = ThemeColor(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x1F1F22))
    public static let border = ThemeColor(light: Color(hex: 0xE3E3E6), dark: Color(hex: 0x2C2C30))

    // Brand accent (constant across appearances — the fixed brand moment)
    public static let accent = ThemeColor(Color(hex: 0xE50914))
    public static let accentBright = ThemeColor(Color(hex: 0xFF1E27))
    public static let accentPressed = ThemeColor(Color(hex: 0xB00610))
    public static let onAccent = ThemeColor(Color(hex: 0xFFFFFF))

    // Text
    public static let textPrimary = ThemeColor(light: Color(hex: 0x0A0A0B), dark: Color(hex: 0xF5F5F7))
    public static let textSecondary = ThemeColor(Color(hex: 0x8E8E93))
    public static let textTertiary = ThemeColor(light: Color(hex: 0xB8B8BE), dark: Color(hex: 0xA1A1AA))

    // Phase colors (never the only signal — always paired with a label/icon)
    public static let phasePrepare = ThemeColor(light: Color(hex: 0xD98A00), dark: Color(hex: 0xF5A623))
    public static let phaseRound = ThemeColor(light: Color(hex: 0xE50914), dark: Color(hex: 0xFF1E27))
    public static let phaseRest = ThemeColor(light: Color(hex: 0x0E9C8E), dark: Color(hex: 0x17C3B2))
    public static let phaseFinished = ThemeColor(light: Color(hex: 0x0A0A0B), dark: Color(hex: 0xF5F5F7))
    public static let trackDim = ThemeColor(light: Color(hex: 0xE3E3E6), dark: Color(hex: 0x1F1F22))

    // Status
    public static let success = ThemeColor(light: Color(hex: 0x0E9C8E), dark: Color(hex: 0x17C3B2))
    public static let danger = ThemeColor(Color(hex: 0xE50914))

    /// The categorical chart color for a workout-type series (DESIGN §7.5). Constant across
    /// appearances — validated with the dataviz skill against both surfaces. The chart's Total line
    /// uses `textPrimary`, not a series color.
    public static func chartColor(for type: WorkoutType) -> ThemeColor {
        switch type {
        case .shadowBoxing: return ThemeColor(Color(hex: 0xE50914))
        case .skipping: return ThemeColor(Color(hex: 0x0E9C8E))
        case .heavyBag: return ThemeColor(Color(hex: 0xB8770A))
        case .speedBall: return ThemeColor(Color(hex: 0x2E6FE0))
        case .sparring: return ThemeColor(Color(hex: 0xB23A8A))
        }
    }
}

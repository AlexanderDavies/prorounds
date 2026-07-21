import SwiftUI
import ProRoundsDataSettings

public extension ColorSchemePreference {
    /// The SwiftUI color scheme to force, or `nil` to follow the device (System).
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

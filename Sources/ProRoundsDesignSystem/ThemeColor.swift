import SwiftUI

public extension Color {
    /// Builds an opaque sRGB color from a 0xRRGGBB literal. The one place raw hex is written —
    /// the implementation of the `DESIGN.md` §3 palette.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// A semantic color that resolves to a different value in light and dark appearance. Conforms to
/// `ShapeStyle`, so it drops into `.foregroundStyle`, `.fill`, `.background`, etc., and picks the
/// right value from the view's `colorScheme` — no asset catalog required (keeps the module buildable
/// without `actool`).
public struct ThemeColor: ShapeStyle, Sendable, Equatable {
    public let light: Color
    public let dark: Color

    public init(light: Color, dark: Color) {
        self.light = light
        self.dark = dark
    }

    /// A color that is the same in both appearances (e.g. the constant brand red).
    public init(_ constant: Color) {
        self.light = constant
        self.dark = constant
    }

    public func resolve(in environment: EnvironmentValues) -> Color.Resolved {
        color(for: environment.colorScheme).resolve(in: environment)
    }

    /// The concrete `Color` for a given scheme (useful where a plain `Color` is required).
    public func color(for scheme: ColorScheme) -> Color {
        scheme == .dark ? dark : light
    }
}

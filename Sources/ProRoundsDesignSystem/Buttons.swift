import SwiftUI

// MARK: - Text button styles (DESIGN.md §6.1)

/// Primary action: accent fill, pill, on-accent label. Height 52, press → scale 0.97 + darker fill.
public struct PrimaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        StyledLabel(configuration: configuration) { pressed, enabled in
            configuration.label
                .fontToken(.bodyEmphasis)
                .foregroundStyle(ProRoundsColor.onAccent)
                .padding(.horizontal, Spacing.lg)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    pressed ? AnyShapeStyle(ProRoundsColor.accentPressed) : AnyShapeStyle(ProRoundsColor.accent),
                    in: Capsule()
                )
                .opacity(enabled ? 1 : 0.4)
                .scaleEffect(pressed ? 0.97 : 1)
        }
    }
}

/// Secondary: transparent with a hairline border and primary-text label.
public struct SecondaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        StyledLabel(configuration: configuration) { pressed, enabled in
            configuration.label
                .fontToken(.bodyEmphasis)
                .foregroundStyle(ProRoundsColor.textPrimary)
                .padding(.horizontal, Spacing.lg)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .overlay(Capsule().strokeBorder(ProRoundsColor.border, lineWidth: 1.5))
                .opacity(enabled ? (pressed ? 0.7 : 1) : 0.4)
                .scaleEffect(pressed ? 0.97 : 1)
        }
    }
}

/// Tertiary / text: no fill, accent label. For inline actions.
public struct TertiaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        StyledLabel(configuration: configuration) { pressed, enabled in
            configuration.label
                .fontToken(.bodyEmphasis)
                .foregroundStyle(ProRoundsColor.accent)
                .opacity(enabled ? (pressed ? 0.6 : 1) : 0.4)
        }
    }
}

/// Destructive: no fill, danger label (e.g. delete a config).
public struct DestructiveButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        StyledLabel(configuration: configuration) { pressed, enabled in
            configuration.label
                .fontToken(.bodyEmphasis)
                .foregroundStyle(ProRoundsColor.danger)
                .opacity(enabled ? (pressed ? 0.6 : 1) : 0.4)
        }
    }
}

// MARK: - Circular / icon button styles (DESIGN.md §6.4)

/// The large primary transport control: a 72-pt accent circle with a white glyph.
public struct PrimaryCircleButtonStyle: ButtonStyle {
    public var diameter: CGFloat = 72
    public init(diameter: CGFloat = 72) { self.diameter = diameter }
    public func makeBody(configuration: Configuration) -> some View {
        StyledLabel(configuration: configuration) { pressed, enabled in
            configuration.label
                .font(.system(size: diameter * 0.36, weight: .bold))
                .foregroundStyle(ProRoundsColor.onAccent)
                .frame(width: diameter, height: diameter)
                .background(
                    pressed ? AnyShapeStyle(ProRoundsColor.accentPressed) : AnyShapeStyle(ProRoundsColor.accent),
                    in: Circle()
                )
                .opacity(enabled ? 1 : 0.4)
                .scaleEffect(pressed ? 0.97 : 1)
        }
    }
}

/// A secondary circular icon button (e.g. reset): raised surface, primary-text glyph.
public struct IconButtonStyle: ButtonStyle {
    public var diameter: CGFloat = 52
    public init(diameter: CGFloat = 52) { self.diameter = diameter }
    public func makeBody(configuration: Configuration) -> some View {
        StyledLabel(configuration: configuration) { pressed, enabled in
            configuration.label
                .font(.system(size: diameter * 0.4, weight: .semibold))
                .foregroundStyle(ProRoundsColor.textPrimary)
                .frame(width: diameter, height: diameter)
                .background(ProRoundsColor.surfaceRaised, in: Circle())
                .overlay(Circle().strokeBorder(ProRoundsColor.border, lineWidth: 1))
                .opacity(enabled ? (pressed ? 0.7 : 1) : 0.4)
                .scaleEffect(pressed ? 0.97 : 1)
        }
    }
}

// MARK: - Shared enabled/pressed plumbing

/// Bridges `ButtonStyle` (not a View) to the environment's `isEnabled`, handing both the pressed and
/// enabled flags to the label builder.
private struct StyledLabel<Content: View>: View {
    let configuration: ButtonStyleConfiguration
    @ViewBuilder let content: (_ pressed: Bool, _ enabled: Bool) -> Content
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        content(configuration.isPressed, isEnabled)
    }
}

// MARK: - Convenience

public extension ButtonStyle where Self == PrimaryButtonStyle {
    static var proPrimary: PrimaryButtonStyle { .init() }
}
public extension ButtonStyle where Self == SecondaryButtonStyle {
    static var proSecondary: SecondaryButtonStyle { .init() }
}
public extension ButtonStyle where Self == TertiaryButtonStyle {
    static var proTertiary: TertiaryButtonStyle { .init() }
}
public extension ButtonStyle where Self == DestructiveButtonStyle {
    static var proDestructive: DestructiveButtonStyle { .init() }
}
public extension ButtonStyle where Self == PrimaryCircleButtonStyle {
    static var proPrimaryCircle: PrimaryCircleButtonStyle { .init() }
}
public extension ButtonStyle where Self == IconButtonStyle {
    static var proIcon: IconButtonStyle { .init() }
}

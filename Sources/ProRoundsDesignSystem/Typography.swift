import SwiftUI

/// A typography role (`DESIGN.md` §4) expressed as data — size, weight, monospaced digits, and
/// tracking — so the scale is unit-testable without introspecting an opaque `Font`. Apply `.font`
/// (and `.tracking(token.tracking)` where the design calls for it).
public struct FontToken: Sendable, Equatable {
    public let size: CGFloat
    public let weight: Font.Weight
    public let monospacedDigits: Bool
    /// Letter spacing in points (negative tightens large display type).
    public let tracking: CGFloat

    public init(size: CGFloat, weight: Font.Weight, monospacedDigits: Bool = false, tracking: CGFloat = 0) {
        self.size = size
        self.weight = weight
        self.monospacedDigits = monospacedDigits
        self.tracking = tracking
    }

    public var font: Font {
        let base = Font.system(size: size, weight: weight)
        return monospacedDigits ? base.monospacedDigit() : base
    }
}

/// The typography scale (`DESIGN.md` §4), as static tokens so the leading-dot form
/// (`.fontToken(.timer)`) works. The timer roles use monospaced digits so the numeral never reflows
/// as digits change.
public extension FontToken {
    static let timer = FontToken(size: 96, weight: .bold, monospacedDigits: true, tracking: -2)
    static let timerSmall = FontToken(size: 56, weight: .bold, monospacedDigits: true, tracking: -1)
    static let display = FontToken(size: 34, weight: .bold, tracking: -1)
    static let title = FontToken(size: 28, weight: .bold)
    static let headline = FontToken(size: 20, weight: .semibold)
    static let body = FontToken(size: 17, weight: .regular)
    static let bodyEmphasis = FontToken(size: 17, weight: .semibold)
    static let subhead = FontToken(size: 15, weight: .regular)
    static let caption = FontToken(size: 13, weight: .medium, tracking: 0.5)
    static let overline = FontToken(size: 11, weight: .bold, tracking: 1)
    // Coaching ticker (mockup-stage values): the call reads large, the other convention sits small
    // above it, and the modifier is quieter still.
    static let coachCall = FontToken(size: 24, weight: .semibold)
    static let coachNumbers = FontToken(size: 13, weight: .medium, tracking: 1)
    static let coachModifier = FontToken(size: 14, weight: .regular)
}

/// Namespaced alias for the typography scale (`ProRoundsFont.timer` == `FontToken.timer`).
public typealias ProRoundsFont = FontToken

public extension Text {
    /// Applies a `FontToken`'s font and tracking.
    func fontToken(_ token: FontToken) -> Text {
        font(token.font).tracking(token.tracking)
    }
}

public extension View {
    /// Applies a `FontToken`'s font and tracking to any view.
    func fontToken(_ token: FontToken) -> some View {
        font(token.font).tracking(token.tracking)
    }
}

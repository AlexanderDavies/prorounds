import SwiftUI

/// The current coaching call on the running screen.
///
/// Shows the call in both naming conventions at once — numbers small above, names large below —
/// which is what teaches the mapping passively rather than making the athlete look it up. It is also
/// the only channel for a user who cannot hear the coach, so it carries every call, not a summary.
///
/// All strings are injected and pre-formatted; the component does no lookup (guide §3.3).
public struct CoachTickerView: View {
    public let primary: String
    public let secondary: String?
    public let modifier: String?
    /// One phrase for assistive technology, since three fragments announced separately lose the
    /// instruction.
    public let accessibleDescription: String

    public init(primary: String, secondary: String?, modifier: String?, accessibleDescription: String) {
        self.primary = primary
        self.secondary = secondary
        self.modifier = modifier
        self.accessibleDescription = accessibleDescription
    }

    public var body: some View {
        VStack(spacing: Spacing.xxs) {
            if let secondary {
                Text(secondary)
                    .fontToken(.coachNumbers)
                    .foregroundStyle(ProRoundsColor.textSecondary)
                    .lineLimit(1)
            }
            Text(primary)
                .fontToken(.coachCall)
                .foregroundStyle(ProRoundsColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let modifier {
                Text(modifier)
                    .fontToken(.coachModifier)
                    .foregroundStyle(ProRoundsColor.accent)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibleDescription)
    }
}

#Preview("CoachTicker") {
    VStack(spacing: Spacing.lg) {
        CoachTickerView(primary: "Jab Cross", secondary: "1 · 2", modifier: "to the body",
                        accessibleDescription: "Jab Cross, to the body")
        CoachTickerView(primary: "Circle left", secondary: nil, modifier: nil,
                        accessibleDescription: "Circle left")
        CoachTickerView(primary: "Jab Cross Hook", secondary: "1 · 2 · 3", modifier: nil,
                        accessibleDescription: "Jab Cross Hook")
    }
    .padding()
    .background(ProRoundsColor.canvas)
}

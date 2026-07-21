import SwiftUI

/// A pill showing the current phase's overline label in the phase color over a tinted fill
/// (`DESIGN.md` §6.3). Pairs color with text so it never relies on color alone. Takes an already-
/// formatted label (e.g. "ROUND 3 / 12") and the phase color — no product logic.
public struct PhaseBadge: View {
    public let label: String
    public let color: ThemeColor

    public init(label: String, color: ThemeColor) {
        self.label = label
        self.color = color
    }

    public var body: some View {
        Text(label.uppercased())
            .fontToken(.overline)
            .foregroundStyle(color)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(color.opacity(0.16), in: Capsule())
            .accessibilityLabel(label)
    }
}

#Preview("PhaseBadge") {
    VStack(spacing: Spacing.md) {
        PhaseBadge(label: "Prepare", color: ProRoundsColor.phasePrepare)
        PhaseBadge(label: "Round 3 / 12", color: ProRoundsColor.phaseRound)
        PhaseBadge(label: "Rest", color: ProRoundsColor.phaseRest)
        PhaseBadge(label: "Done", color: ProRoundsColor.phaseFinished)
    }
    .padding()
}

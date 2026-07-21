import SwiftUI

/// The workout hero (`DESIGN.md` §6.2): a phase-colored progress arc over a dim track, with a center
/// stack of the phase badge, the timer numeral, and a small total-remaining readout. Everything is
/// injected and pre-formatted — `progress` is a 0…1 fraction, `numeral` is already resolved for the
/// user's count direction (§7.6) — so the ring holds no timing logic and snapshots deterministically.
public struct TimerRing: View {
    public let progress: Double
    public let phaseColor: ThemeColor
    public let badgeLabel: String
    public let numeral: String
    public let totalRemaining: String
    public var diameter: CGFloat
    public var lineWidth: CGFloat

    public init(
        progress: Double,
        phaseColor: ThemeColor,
        badgeLabel: String,
        numeral: String,
        totalRemaining: String,
        diameter: CGFloat = 320,
        lineWidth: CGFloat = 14
    ) {
        self.progress = min(max(progress, 0), 1)
        self.phaseColor = phaseColor
        self.badgeLabel = badgeLabel
        self.numeral = numeral
        self.totalRemaining = totalRemaining
        self.diameter = diameter
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(ProRoundsColor.trackDim, style: StrokeStyle(lineWidth: lineWidth))
            Circle()
                .trim(from: 0, to: progress)
                .stroke(phaseColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90)) // start at 12 o'clock

            VStack(spacing: Spacing.xs) {
                PhaseBadge(label: badgeLabel, color: phaseColor)
                Text(numeral)
                    .fontToken(.timer)
                    .foregroundStyle(ProRoundsColor.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(totalRemaining)
                    .fontToken(.caption)
                    .foregroundStyle(ProRoundsColor.textSecondary)
            }
            .padding(lineWidth * 2)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(badgeLabel), \(numeral) remaining")
    }
}

#Preview("TimerRing") {
    HStack(spacing: 24) {
        TimerRing(progress: 0.62, phaseColor: ProRoundsColor.phaseRound,
                  badgeLabel: "Round 3 / 12", numeral: "01:23", totalRemaining: "12:40 left",
                  diameter: 260)
        TimerRing(progress: 0.3, phaseColor: ProRoundsColor.phaseRest,
                  badgeLabel: "Rest", numeral: "00:18", totalRemaining: "11:05 left",
                  diameter: 260)
    }
    .padding()
}

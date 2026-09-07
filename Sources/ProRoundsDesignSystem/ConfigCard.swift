import SwiftUI

/// A saved-configuration row (`DESIGN.md` §6.5): a workout-type icon in an accent-tinted circle, the
/// config name, a metadata line, and a trailing total chip + chevron. All strings are injected and
/// pre-formatted (name, metadata, total) — no product logic, no data fetch.
public struct ConfigCard: View {
    public let iconSystemName: String
    public let name: String
    public let metadata: String
    public let totalText: String
    /// The coaching level's name when the workout is coached, otherwise nil.
    ///
    /// Carries the level's *name* rather than merely marking the card as coached, so a second level
    /// is a new string rather than a redesign. Defaulted to nil so every existing call site — and
    /// every existing snapshot — is unaffected.
    public let coachingBadge: String?

    public init(
        iconSystemName: String,
        name: String,
        metadata: String,
        totalText: String,
        coachingBadge: String? = nil
    ) {
        self.iconSystemName = iconSystemName
        self.name = name
        self.metadata = metadata
        self.totalText = totalText
        self.coachingBadge = coachingBadge
    }

    public var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle().fill(ProRoundsColor.accent.opacity(0.16))
                Image(systemName: iconSystemName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(ProRoundsColor.accent)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(name)
                    .fontToken(.headline)
                    .foregroundStyle(ProRoundsColor.textPrimary)
                    .lineLimit(1)
                HStack(spacing: Spacing.xs) {
                    Text(metadata)
                        .fontToken(.subhead)
                        .foregroundStyle(ProRoundsColor.textSecondary)
                        .lineLimit(1)
                    if let coachingBadge {
                        Text(coachingBadge)
                            .fontToken(.caption)
                            .foregroundStyle(ProRoundsColor.accent)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 1)
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.sm)
                                    .stroke(ProRoundsColor.accent.opacity(0.5), lineWidth: 1)
                            )
                            .accessibilityLabel("Coached, \(coachingBadge)")
                    }
                }
            }

            Spacer(minLength: Spacing.sm)

            Text(totalText)
                .fontToken(.caption)
                .foregroundStyle(ProRoundsColor.textSecondary)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ProRoundsColor.textTertiary)
        }
        .padding(Spacing.md)
        .background(ProRoundsColor.surfaceRaised, in: RoundedRectangle(cornerRadius: Radius.lg))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(metadata), \(totalText)")
    }
}

#Preview("ConfigCard") {
    VStack(spacing: Spacing.md) {
        ConfigCard(iconSystemName: "figure.boxing", name: "Heavy Bag Blast",
                   metadata: "12 × 3:00 · 1:00 rest", totalText: "47:10")
        ConfigCard(iconSystemName: "figure.jumprope", name: "Quick Shadow",
                   metadata: "3 × 2:00 · 0:30 rest", totalText: "7:00")
    }
    .padding()
    .background(ProRoundsColor.canvas)
}

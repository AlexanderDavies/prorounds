import Foundation
import ProRoundsDataConfig
import ProRoundsFoundationUtilities

/// View-ready row for the Configurations list — every string pre-formatted, so the view does no
/// formatting (guide §3.3).
struct ConfigRowDisplay: Equatable, Identifiable {
    let id: UUID
    let name: String
    let metadata: String      // "12 × 3:00 · 1:00 rest"
    let totalText: String     // "47:10"
    let iconSystemName: String
    /// The coaching level's name when coached, otherwise nil — pre-formatted like every other
    /// string here, so the view does no lookup.
    let coachingBadge: String?
}

/// Maps a domain `Configuration` to its list row via the single-source calculators/formatters.
enum ConfigDisplayMapper {
    static func row(_ config: Configuration) -> ConfigRowDisplay {
        let metadata = "\(config.rounds) × \(DurationFormat.clock(config.roundDuration))"
            + " · \(DurationFormat.clock(config.restDuration)) rest"
        return ConfigRowDisplay(
            id: config.id,
            name: config.effectiveName,
            metadata: metadata,
            totalText: DurationFormat.clock(config.totalDuration),
            iconSystemName: icon(for: config.workoutType),
            coachingBadge: config.coachingLevel?.displayName
        )
    }

    /// SF Symbol per workout type (DESIGN §5). Availability varies by iOS version; these resolve on
    /// the iOS 17+ deployment target.
    static func icon(for type: WorkoutType) -> String {
        switch type {
        case .shadowBoxing: return "figure.boxing"
        case .skipping: return "figure.jumprope"
        case .heavyBag: return "figure.kickboxing"
        case .speedBall: return "circle.circle"
        case .sparring: return "figure.martial.arts"
        }
    }
}

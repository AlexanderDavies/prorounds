import ProRoundsFoundationUtilities

/// How much the coach says, and how advanced the combinations are.
///
/// `nil` on a `Configuration` means coaching is off — the absence of a choice rather than a kind of
/// coaching, which is also what keeps the persistence column optional and its migration lightweight.
///
/// Adding a level is additive here and requires no change to `WorkoutType`. Coached variants inside
/// that enumeration were rejected outright: it is load-bearing across auto-naming, the session model
/// and the chart legend.
public enum CoachingLevel: String, CaseIterable, Codable, Sendable, Equatable {
    case beginner

    public var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        }
    }
}

public extension WorkoutType {
    /// Whether a coach script exists for this workout type.
    ///
    /// The single source both `ConfigurationValidator` and the editor read, so the rule and the UI
    /// cannot disagree about what is offerable. Shadow Boxing and Heavy Bag only in v1 — their
    /// scripts genuinely differ, because bag work needs a longer cadence while you recover the bag.
    var supportsCoaching: Bool {
        switch self {
        case .shadowBoxing, .heavyBag: return true
        case .skipping, .speedBall, .sparring: return false
        }
    }
}

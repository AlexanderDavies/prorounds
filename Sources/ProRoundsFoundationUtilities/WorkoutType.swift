import Foundation

/// The five workout types, in the order the product spec presents them. A pure, dependency-free
/// domain primitive; it lives in Foundation so both the config and session data layers can share
/// it without a cross-layer dependency.
public enum WorkoutType: String, CaseIterable, Codable, Sendable, Equatable {
    case shadowBoxing
    case skipping
    case heavyBag
    case speedBall
    case sparring

    /// Human-readable name used in titles, auto-names, and the chart legend.
    public var displayName: String {
        switch self {
        case .shadowBoxing: return "Shadow Boxing"
        case .skipping: return "Skipping"
        case .heavyBag: return "Heavy Bag"
        case .speedBall: return "Speed Ball"
        case .sparring: return "Sparring"
        }
    }
}

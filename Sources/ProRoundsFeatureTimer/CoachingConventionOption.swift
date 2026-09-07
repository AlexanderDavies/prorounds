import Foundation

/// One naming-convention choice, already resolved to what the user sees.
///
/// The convention type itself lives in the coaching module, which this module deliberately cannot
/// name — so the options arrive as strings from the composition root, exactly as the ticker's text
/// does. That is what keeps the timer free of any route to the coaching module, and therefore to the
/// entitlement.
public struct CoachingConventionOption: Identifiable, Equatable, Sendable {
    public let id: String
    public let label: String
    public let isSelected: Bool

    public init(id: String, label: String, isSelected: Bool) {
        self.id = id
        self.label = label
        self.isSelected = isSelected
    }
}

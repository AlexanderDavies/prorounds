import Foundation
import ProRoundsDataConfig

/// Routes within the Timer tab (guide §3.4). The running route joins in a later change; today the
/// editor create/edit distinction is all that is needed.
public enum TimerRoute: Hashable {
    /// Present the editor. `nil` id = create a new configuration; an id = edit that one.
    case configEditor(Configuration.ID?)
}

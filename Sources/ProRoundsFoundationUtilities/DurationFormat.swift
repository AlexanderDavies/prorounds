import Foundation

/// Time-to-string formatting for display. The single home for how durations are rendered,
/// so the timer numeral, config metadata, and session summaries never drift apart (guide §6.5).
public enum DurationFormat {
    /// Clock style: `m:ss`, or `h:mm:ss` once the duration reaches an hour. Minutes are padded
    /// only when hours are present, matching the design (e.g. "1:23", "47:10", "1:02:03").
    public static func clock(_ duration: Duration) -> String {
        let totalSeconds = max(0, Int(duration.components.seconds))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return "\(hours):" + String(format: "%02d:%02d", minutes, seconds)
        }
        return "\(minutes):" + String(format: "%02d", seconds)
    }

    /// Compact style used inside auto-generated names: whole minutes as "Nmin", otherwise "M:SS".
    public static func compactMinutes(_ duration: Duration) -> String {
        let totalSeconds = max(0, Int(duration.components.seconds))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return seconds == 0 ? "\(minutes)min" : "\(minutes):" + String(format: "%02d", seconds)
    }
}

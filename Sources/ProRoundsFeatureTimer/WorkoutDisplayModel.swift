import Foundation
import ProRoundsFoundationUtilities

/// A styling bucket for the current phase — the view maps it to a theme color (keeps the display
/// model free of the design system).
public enum WorkoutPhaseStyle: Sendable, Equatable {
    case prepare, round, rest, finished
}

/// View-ready state for the running screen (guide §3.3). All strings are pre-formatted and the
/// count-up/down choice is already resolved here — the view does no timer math.
public struct WorkoutDisplayModel: Equatable, Sendable {
    public let phaseLabel: String            // "Prepare", "Round 3 / 12", "Rest", "Done"
    public let timeLabel: String             // "01:23" — count-up or count-down resolved
    public let totalRemainingLabel: String   // "12:40 left"
    public let progress: Double              // 0…1 filled portion of the ring
    public let phaseStyle: WorkoutPhaseStyle
    public let isStarted: Bool          // false before the first Play and after reset (idle/ready)
    public let isRunning: Bool
    public let isPaused: Bool
    public let isFinished: Bool

    public init(_ snapshot: WorkoutSnapshot, direction: CountDirection) {
        let phaseDuration = snapshot.remaining + snapshot.elapsedInPhase

        switch snapshot.phase {
        case .preparing:
            phaseLabel = "Prepare"
            phaseStyle = .prepare
        case .round(let index):
            phaseLabel = "Round \(index) / \(snapshot.roundCount)"
            phaseStyle = .round
        case .resting:
            phaseLabel = "Rest"
            phaseStyle = .rest
        case .finished:
            phaseLabel = "Done"
            phaseStyle = .finished
        }

        let shown = direction == .countDown ? snapshot.remaining : snapshot.elapsedInPhase
        timeLabel = DurationFormat.clock(shown)

        let totalRemaining = snapshot.totalDuration - snapshot.elapsedTotal
        totalRemainingLabel = "\(DurationFormat.clock(totalRemaining)) left"

        isFinished = snapshot.phase == .finished
        isStarted = snapshot.started
        isPaused = snapshot.isPaused
        // Idle (not started) and paused both surface Play; only a started, unpaused, unfinished
        // workout is "running" (shows Pause).
        isRunning = snapshot.started && !snapshot.isPaused && !isFinished

        if isFinished {
            progress = 1
        } else {
            let phaseSeconds = Self.seconds(phaseDuration)
            let remainingSeconds = Self.seconds(snapshot.remaining)
            progress = phaseSeconds > 0 ? min(max(remainingSeconds / phaseSeconds, 0), 1) : 0
        }
    }

    private static func seconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
    }
}

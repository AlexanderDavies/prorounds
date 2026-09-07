import Foundation
import Observation
import ProRoundsDataConfig
import ProRoundsDataSessions
import ProRoundsFoundationAudio
import ProRoundsFoundationUtilities

/// Drives the running workout screen (guide §3.2): starts and observes the `RoundTimerEngine`, maps
/// snapshots to a `WorkoutDisplayModel`, keeps the screen awake, and pauses/resumes across audio
/// interruptions. It never sequences time itself — that is the engine's job.
@MainActor
@Observable
public final class WorkoutViewModel {
    public private(set) var display: WorkoutDisplayModel
    public let title: String
    /// True when saving the completed session failed; the finished screen offers a Retry.
    public private(set) var saveFailed = false

    private let configuration: Configuration
    private let engine: RoundTimerEngine
    private let idleTimer: any IdleTimerControlling
    private let interruptions: any AudioInterruptionMonitoring
    private let sessions: any SessionRepository
    private let countDirection: CountDirection
    private let configurationWriter: (any ConfigurationWriting)?
    private let minimalScreen: Bool
    /// The coaching level as last successfully stored. Held here rather than read from the original
    /// configuration so the chip never claims a level a failed save did not persist.
    private var coachingLevel: CoachingLevel?

    private var snapshotTask: Task<Void, Never>?
    private var interruptionTask: Task<Void, Never>?
    private var pausedByInterruption = false
    private var pendingSession: Session?
    private var didAttemptSave = false

    public init(
        configuration: Configuration,
        engine: RoundTimerEngine,
        idleTimer: any IdleTimerControlling,
        interruptions: any AudioInterruptionMonitoring,
        sessions: any SessionRepository,
        countDirection: CountDirection = .countDown,
        configurationWriter: (any ConfigurationWriting)? = nil,
        minimalScreen: Bool = false
    ) {
        self.configuration = configuration
        self.title = configuration.effectiveName
        self.engine = engine
        self.idleTimer = idleTimer
        self.interruptions = interruptions
        self.sessions = sessions
        self.countDirection = countDirection
        self.configurationWriter = configurationWriter
        self.minimalScreen = minimalScreen
        self.coachingLevel = configuration.coachingLevel
        self.display = WorkoutDisplayModel(
            engine.snapshot, direction: countDirection, workoutType: configuration.workoutType,
            coachingLevel: configuration.coachingLevel, minimalScreen: minimalScreen)
    }

    private func makeDisplay(_ snapshot: WorkoutSnapshot) -> WorkoutDisplayModel {
        WorkoutDisplayModel(snapshot, direction: countDirection,
                            workoutType: configuration.workoutType,
                            coachingLevel: coachingLevel, minimalScreen: minimalScreen)
    }

    /// Sets the coaching level for this workout, writing through to the same stored value the
    /// configuration editor writes.
    ///
    /// The displayed level is updated only after the save succeeds, so a failed write leaves the
    /// chip telling the truth rather than promising coaching that will not happen.
    public func setCoachingLevel(_ level: CoachingLevel?) async {
        guard let configurationWriter else { return }
        let updated = Configuration(
            id: configuration.id, workoutType: configuration.workoutType,
            rounds: configuration.rounds, roundDuration: configuration.roundDuration,
            restDuration: configuration.restDuration, prepDuration: configuration.prepDuration,
            warningLead: configuration.warningLead, customName: configuration.customName,
            coachingLevel: level)
        do {
            try await configurationWriter.save(updated)
            coachingLevel = level
            display = makeDisplay(engine.snapshot)
        } catch {
            // Left as it was: the chip must not claim a level that was never stored.
        }
    }

    /// One-line summary shown on the finished screen (rounds · total time).
    public var finishedSummary: String {
        "\(engine.snapshot.roundCount) rounds · \(DurationFormat.clock(engine.snapshot.totalDuration))"
    }

    /// Wires up observation and shows the ready (idle) state. It does NOT start the engine — the
    /// workout begins when the user taps Play (`playPause()`), so opening the screen (or returning
    /// from Settings, which resets the engine) always lands on a startable ready screen.
    public func onAppear() {
        idleTimer.setDisabled(true)
        display = makeDisplay(engine.snapshot)
        snapshotTask = Task { [weak self] in
            guard let self else { return }
            for await snapshot in self.engine.snapshots {
                self.display = WorkoutDisplayModel(snapshot, direction: self.countDirection)
                if snapshot.phase == .finished {
                    self.idleTimer.setDisabled(false)
                    self.saveCompletedSession()
                }
            }
        }
        interruptionTask = Task { [weak self] in
            guard let self else { return }
            for await event in self.interruptions.events {
                switch event {
                case .began: self.handleInterruptionBegan()
                case .ended: self.handleInterruptionEnded()
                }
            }
        }
    }

    /// The primary transport intent: start the workout from idle, otherwise toggle pause/resume.
    public func playPause() {
        if engine.snapshot.started {
            engine.togglePause()
        } else {
            engine.start()
        }
        // Reflect the new transport state immediately (no Play→Pause flash while the stream catches up).
        display = makeDisplay(engine.snapshot)
    }

    public func togglePause() {
        engine.togglePause()
    }

    public func reset() {
        engine.reset()
        idleTimer.setDisabled(false)
    }

    /// Called when the screen is left — stop the workout and restore normal idle behaviour.
    public func onDisappear() {
        engine.reset()
        idleTimer.setDisabled(false)
        snapshotTask?.cancel()
        interruptionTask?.cancel()
    }

    private func handleInterruptionBegan() {
        guard !engine.snapshot.isPaused, engine.snapshot.phase != .finished else { return }
        engine.togglePause()
        pausedByInterruption = true
    }

    private func handleInterruptionEnded() {
        guard pausedByInterruption, engine.snapshot.isPaused else { return }
        engine.togglePause()
        pausedByInterruption = false
    }

    // MARK: - Session persistence

    /// Saves the completed workout as a session, exactly once (the finished snapshot may re-yield).
    private func saveCompletedSession() {
        guard !didAttemptSave else { return }
        didAttemptSave = true
        let session = Session(completed: configuration, at: Date())
        pendingSession = session
        persist(session)
    }

    /// Retries a failed session save (from the finished screen).
    public func retrySave() {
        guard saveFailed, let session = pendingSession else { return }
        persist(session)
    }

    private func persist(_ session: Session) {
        saveFailed = false
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.sessions.save(session)
                self.pendingSession = nil
            } catch {
                self.saveFailed = true
            }
        }
    }
    // The observation tasks capture `self` weakly and are cancelled in `onDisappear`; they also end
    // when their streams finish (the engine's snapshots stream finishes when the engine deallocates).
}

import Foundation
import ProRoundsDataConfig
import ProRoundsFoundationAudio
import ProRoundsFoundationTiming

/// The deterministic round-timer engine — ProRounds' core. It sequences a workout as
/// `preparing → (round → resting) × N` (no rest after the final round), times each phase by an
/// **absolute monotonic deadline** (never a decremented tick counter, guide §7.2), emits audio
/// cues at transitions and the warning lead, and publishes `WorkoutSnapshot`s.
///
/// The state transitions live in a synchronous core (`beginTimeline(at:)`, `processTick(at:)`,
/// `pause(at:)`, `resume(at:)`) returning the cues to emit, so an entire workout is verified
/// deterministically against a `FakeTimeSource` in microseconds. The public transport methods read
/// the injected `TimeSource` and drive that core; an async tick loop pumps `processTick` and plays
/// the returned cues.
@MainActor
public final class RoundTimerEngine {
    private let config: Configuration
    private let warningSound: WarningSound
    private let timeSource: any TimeSource
    private let player: any AudioCuePlayer
    private let tickInterval: Duration

    public private(set) var snapshot: WorkoutSnapshot {
        didSet { snapshotContinuation.yield(snapshot) }
    }

    /// A stream of snapshots the UI observes; every change to `snapshot` is yielded (§7). Consumed by
    /// the workout view model; the current value is always readable via `snapshot`.
    public let snapshots: AsyncStream<WorkoutSnapshot>
    private let snapshotContinuation: AsyncStream<WorkoutSnapshot>.Continuation

    // Timing state (deadline-based; never a tick accumulator).
    private var started = false
    private var phase: WorkoutPhase = .preparing
    private var phaseStart: ContinuousClock.Instant = ContinuousClock().now
    private var deadline: ContinuousClock.Instant = ContinuousClock().now
    private var warningFired = false
    private var isPaused = false
    private var pausedRemaining: Duration = .zero
    private var elapsedBeforeCurrentPhase: Duration = .zero
    private var tickTask: Task<Void, Never>?

    public init(
        configuration: Configuration,
        timeSource: any TimeSource,
        player: any AudioCuePlayer,
        warningSound: WarningSound = .woodenClap,
        tickInterval: Duration = .milliseconds(100)
    ) {
        self.config = configuration
        self.timeSource = timeSource
        self.player = player
        self.warningSound = warningSound
        self.tickInterval = tickInterval
        (self.snapshots, self.snapshotContinuation) = AsyncStream.makeStream()
        self.snapshot = Self.initialSnapshot(for: configuration)
        snapshotContinuation.yield(snapshot) // initial (didSet doesn't fire during init)
    }

    deinit { tickTask?.cancel() }

    // MARK: - Public transport (read the clock, drive the core, pump the async loop)

    public func start() {
        let cues = beginTimeline(at: timeSource.now)
        startTickLoop()
        Task { [player] in
            await player.prepare()
            await self.emit(cues)
        }
    }

    public func togglePause() {
        guard started, phase != .finished else { return }
        _ = isPaused ? resume(at: timeSource.now) : pause(at: timeSource.now)
    }

    public func reset() {
        tickTask?.cancel()
        tickTask = nil
        started = false
        isPaused = false
        warningFired = false
        elapsedBeforeCurrentPhase = .zero
        phase = Self.firstPhase(for: config)
        snapshot = Self.initialSnapshot(for: config)
    }

    private func startTickLoop() {
        tickTask?.cancel()
        // Create the stream synchronously so its continuation is registered before any tick is
        // emitted — otherwise ticks emitted immediately after start() would be dropped.
        let stream = timeSource.ticks(interval: tickInterval)
        tickTask = Task { [weak self] in
            for await instant in stream {
                guard let self else { return }
                let cues = self.processTick(at: instant)
                await self.emit(cues)
            }
        }
    }

    private func emit(_ cues: [AudioCue]) async {
        for cue in cues { await player.play(cue) }
    }

    // MARK: - Synchronous core (deterministic; unit-tested directly)

    /// Anchors the timeline at `now` and returns the initial cues. Prep is skipped when zero.
    func beginTimeline(at now: ContinuousClock.Instant) -> [AudioCue] {
        started = true
        isPaused = false
        warningFired = false
        elapsedBeforeCurrentPhase = .zero

        guard config.rounds > 0 else {
            phase = .finished
            snapshot = makeSnapshot(at: now)
            return [.workoutComplete]
        }

        var cues: [AudioCue] = []
        if config.prepDuration > .zero {
            phase = .preparing
        } else {
            phase = .round(index: 1)
            cues.append(.roundStart)
        }
        phaseStart = now
        deadline = now.advanced(by: duration(of: phase))
        snapshot = makeSnapshot(at: now)
        return cues
    }

    /// Advances the timeline to `now`, firing any cues whose instants have been crossed.
    func processTick(at now: ContinuousClock.Instant) -> [AudioCue] {
        guard started, !isPaused, phase != .finished else { return [] }
        var cues: [AudioCue] = []

        while true {
            // Round-end warning at deadline − lead (clamped to the round start), once per round.
            if case .round = phase, config.warningLead > .zero, !warningFired {
                let warningInstant = warningInstantForCurrentRound()
                if now >= warningInstant {
                    cues.append(.roundEndWarning(warningSound))
                    warningFired = true
                }
            }

            guard now >= deadline, phase != .finished else { break }

            cues.append(contentsOf: endCues(of: phase))
            // Prep is a lead-in — it does not count toward the workout total (the clock starts at round 1).
            if phase != .preparing { elapsedBeforeCurrentPhase += duration(of: phase) }
            let next = Self.phase(after: phase, rounds: config.rounds)
            phaseStart = deadline
            phase = next
            deadline = phaseStart.advanced(by: duration(of: next))
            warningFired = false
            cues.append(contentsOf: startCues(of: next))
            if next == .finished { break }
        }

        snapshot = makeSnapshot(at: now)
        return cues
    }

    func pause(at now: ContinuousClock.Instant) -> [AudioCue] {
        guard started, !isPaused, phase != .finished else { return [] }
        pausedRemaining = clampedRemaining(at: now)
        isPaused = true
        snapshot = makeSnapshot(at: now)
        return []
    }

    func resume(at now: ContinuousClock.Instant) -> [AudioCue] {
        guard started, isPaused else { return [] }
        let phaseDuration = duration(of: phase)
        deadline = now.advanced(by: pausedRemaining)
        phaseStart = deadline.advanced(by: .zero - phaseDuration)
        isPaused = false
        snapshot = makeSnapshot(at: now)
        return []
    }

    // MARK: - Phase helpers

    private func duration(of phase: WorkoutPhase) -> Duration {
        switch phase {
        case .preparing: return config.prepDuration
        case .round: return config.roundDuration
        case .resting: return config.restDuration
        case .finished: return .zero
        }
    }

    private func warningInstantForCurrentRound() -> ContinuousClock.Instant {
        let unclamped = phaseStart.advanced(by: config.roundDuration - config.warningLead)
        return max(phaseStart, unclamped)
    }

    private func endCues(of phase: WorkoutPhase) -> [AudioCue] {
        if case .round = phase { return [.roundEnd] }
        return []
    }

    private func startCues(of phase: WorkoutPhase) -> [AudioCue] {
        switch phase {
        case .round: return [.roundStart]
        case .resting: return [.restStart]
        case .finished: return [.workoutComplete]
        case .preparing: return []
        }
    }

    private static func phase(after phase: WorkoutPhase, rounds: Int) -> WorkoutPhase {
        switch phase {
        case .preparing:
            return .round(index: 1)
        case .round(let index):
            return index < rounds ? .resting(afterRound: index) : .finished
        case .resting(let afterRound):
            return .round(index: afterRound + 1)
        case .finished:
            return .finished
        }
    }

    private static func firstPhase(for config: Configuration) -> WorkoutPhase {
        config.prepDuration > .zero ? .preparing : .round(index: 1)
    }

    // MARK: - Snapshot

    private func clampedRemaining(at now: ContinuousClock.Instant) -> Duration {
        let elapsed = clampedElapsed(at: now)
        return duration(of: phase) - elapsed
    }

    private func clampedElapsed(at now: ContinuousClock.Instant) -> Duration {
        let phaseDuration = duration(of: phase)
        let raw = phaseStart.duration(to: now)
        return max(.zero, min(phaseDuration, raw))
    }

    private func makeSnapshot(at now: ContinuousClock.Instant) -> WorkoutSnapshot {
        if phase == .finished {
            return WorkoutSnapshot(
                phase: .finished,
                remaining: .zero,
                elapsedInPhase: .zero,
                elapsedTotal: config.totalDuration,
                totalDuration: config.totalDuration,
                roundCount: config.rounds,
                isPaused: false,
                started: started
            )
        }
        let elapsedInPhase = clampedElapsed(at: now)
        // Prep is a lead-in: its elapsed time does not accrue to the workout total.
        let elapsedTowardTotal = phase == .preparing ? .zero : elapsedInPhase
        return WorkoutSnapshot(
            phase: phase,
            remaining: duration(of: phase) - elapsedInPhase,
            elapsedInPhase: elapsedInPhase,
            elapsedTotal: elapsedBeforeCurrentPhase + elapsedTowardTotal,
            totalDuration: config.totalDuration,
            roundCount: config.rounds,
            isPaused: isPaused,
            started: started
        )
    }

    private static func initialSnapshot(for config: Configuration) -> WorkoutSnapshot {
        let first = firstPhase(for: config)
        let firstDuration: Duration = config.prepDuration > .zero ? config.prepDuration : config.roundDuration
        return WorkoutSnapshot(
            phase: first,
            remaining: firstDuration,
            elapsedInPhase: .zero,
            elapsedTotal: .zero,
            totalDuration: config.totalDuration,
            roundCount: config.rounds,
            isPaused: false
        )
    }
}

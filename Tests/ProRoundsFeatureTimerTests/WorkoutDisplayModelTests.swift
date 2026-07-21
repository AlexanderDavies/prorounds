import Testing
import Foundation
@testable import ProRoundsFeatureTimer
import ProRoundsFoundationUtilities

@Suite("WorkoutDisplayModel")
struct WorkoutDisplayModelTests {
    private func snapshot(
        phase: WorkoutPhase,
        remaining: Duration,
        elapsedInPhase: Duration,
        elapsedTotal: Duration = .seconds(200),
        total: Duration = .seconds(940),
        rounds: Int = 12,
        paused: Bool = false,
        started: Bool = true
    ) -> WorkoutSnapshot {
        WorkoutSnapshot(phase: phase, remaining: remaining, elapsedInPhase: elapsedInPhase,
                        elapsedTotal: elapsedTotal, totalDuration: total, roundCount: rounds,
                        isPaused: paused, started: started)
    }

    @Test("Count down shows remaining, count up shows elapsed")
    func countDirection() {
        let snap = snapshot(phase: .round(index: 3), remaining: .seconds(83), elapsedInPhase: .seconds(37))
        #expect(WorkoutDisplayModel(snap, direction: .countDown).timeLabel == "1:23")
        #expect(WorkoutDisplayModel(snap, direction: .countUp).timeLabel == "0:37")
    }

    @Test("Phase label and style follow the phase")
    func phaseLabels() {
        let prepare = snapshot(phase: .preparing, remaining: .seconds(10), elapsedInPhase: .zero)
        #expect(WorkoutDisplayModel(prepare, direction: .countDown).phaseLabel == "Prepare")

        let round3 = snapshot(phase: .round(index: 3), remaining: .seconds(83), elapsedInPhase: .seconds(37))
        let round = WorkoutDisplayModel(round3, direction: .countDown)
        #expect(round.phaseLabel == "Round 3 / 12")
        #expect(round.phaseStyle == .round)

        let rest = snapshot(phase: .resting(afterRound: 3), remaining: .seconds(30), elapsedInPhase: .zero)
        #expect(WorkoutDisplayModel(rest, direction: .countDown).phaseLabel == "Rest")
    }

    @Test("Progress is the remaining fraction of the phase; total-remaining is formatted")
    func progressAndTotal() {
        let snap = snapshot(phase: .round(index: 3), remaining: .seconds(83), elapsedInPhase: .seconds(37))
        let model = WorkoutDisplayModel(snap, direction: .countDown)
        #expect(abs(model.progress - 83.0 / 120.0) < 0.001)
        #expect(model.totalRemainingLabel == "12:20 left") // 940 - 200 = 740s
    }

    @Test("Finished shows Done, a full ring, and is not running")
    func finished() {
        let model = WorkoutDisplayModel(
            snapshot(phase: .finished, remaining: .zero, elapsedInPhase: .zero, elapsedTotal: .seconds(940)),
            direction: .countDown
        )
        #expect(model.phaseLabel == "Done")
        #expect(model.isFinished)
        #expect(!model.isRunning)
        #expect(model.progress == 1)
    }

    @Test("Idle (not started) is not running so the control shows Play; started+unpaused is running")
    func idleVsRunning() {
        let idle = snapshot(phase: .preparing, remaining: .seconds(20), elapsedInPhase: .zero, started: false)
        let idleModel = WorkoutDisplayModel(idle, direction: .countDown)
        #expect(!idleModel.isStarted)
        #expect(!idleModel.isRunning) // Play shown to start

        let running = snapshot(phase: .round(index: 1), remaining: .seconds(83), elapsedInPhase: .seconds(37))
        let runningModel = WorkoutDisplayModel(running, direction: .countDown)
        #expect(runningModel.isStarted)
        #expect(runningModel.isRunning) // Pause shown

        let paused = snapshot(phase: .round(index: 1), remaining: .seconds(83), elapsedInPhase: .seconds(37),
                              paused: true)
        let pausedModel = WorkoutDisplayModel(paused, direction: .countDown)
        #expect(pausedModel.isStarted)
        #expect(!pausedModel.isRunning) // Play (resume) shown
    }
}

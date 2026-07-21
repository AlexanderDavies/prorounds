import Foundation
@testable import ProRoundsFeatureTimer
import ProRoundsDataConfig
import ProRoundsFoundationAudio
import ProRoundsFoundationTiming

typealias Instant = ContinuousClock.Instant

@MainActor
enum EngineFixture {
    /// A test engine over whole-second durations. `sound` is the warning sound the engine emits.
    static func make(
        prep: Int,
        round: Int,
        rest: Int,
        rounds: Int,
        lead: Int,
        sound: WarningSound = .buzzer
    ) -> RoundTimerEngine {
        let config = Configuration(
            workoutType: .heavyBag,
            rounds: rounds,
            roundDuration: .seconds(round),
            restDuration: .seconds(rest),
            prepDuration: .seconds(prep),
            warningLead: .seconds(lead)
        )
        return RoundTimerEngine(
            configuration: config,
            timeSource: FakeTimeSource(),
            player: SpyAudioCuePlayer(),
            warningSound: sound
        )
    }
}

@MainActor
extension RoundTimerEngine {
    /// Ticks the engine one second at a time from `t0` for `totalSeconds`, recording every distinct
    /// phase it passes through and every cue it emits (including the initial cues from begin).
    func driveWholeWorkout(from t0: Instant, totalSeconds: Int) -> (phases: [WorkoutPhase], cues: [AudioCue]) {
        var cues = beginTimeline(at: t0)
        var phases = [snapshot.phase]
        var now = t0
        for _ in 0..<totalSeconds {
            now = now.advanced(by: .seconds(1))
            cues += processTick(at: now)
            if phases.last != snapshot.phase { phases.append(snapshot.phase) }
        }
        return (phases, cues)
    }
}

import Testing
import Foundation
@testable import ProRoundsFeatureTimer
import ProRoundsDataConfig
import ProRoundsFoundationAudio
import ProRoundsFoundationTiming
import ProRoundsFoundationUtilities

@MainActor
@Suite("Coaching chip and display")
struct CoachChipTests {
    private func display(
        type: WorkoutType = .heavyBag,
        coaching: CoachingLevel? = nil,
        started: Bool = false,
        call: CoachCallDisplay? = nil,
        minimal: Bool = false
    ) -> WorkoutDisplayModel {
        let snapshot = WorkoutSnapshot(
            phase: started ? .round(index: 1) : .preparing,
            remaining: .seconds(60), elapsedInPhase: .zero, elapsedTotal: .zero,
            totalDuration: .seconds(180), roundCount: 3, isPaused: false,
            started: started, currentCall: call)
        return WorkoutDisplayModel(snapshot, direction: .countDown,
                                   workoutType: type, coachingLevel: coaching, minimalScreen: minimal)
    }

    @Test("the chip names the current level while idle")
    func chipShowsLevel() {
        #expect(display(coaching: .beginner).coachingChipLabel == "Coach: Beginner")
    }

    @Test("the chip reads off when there is no level")
    func chipShowsOff() {
        #expect(display(coaching: nil).coachingChipLabel == "Coach: Off")
    }

    @Test("the chip is offered for a scripted type while idle")
    func chipOfferedWhenIdle() {
        #expect(display(type: .heavyBag).showsCoachingChip)
        #expect(display(type: .shadowBoxing).showsCoachingChip)
    }

    @Test("no chip for a workout type without a script",
          arguments: [WorkoutType.skipping, .speedBall, .sparring])
    func noChipForUnscriptedTypes(type: WorkoutType) {
        #expect(!display(type: type).showsCoachingChip)
    }

    /// Changing the level mid-workout would change a round's plan after it began. Rather than define
    /// what that means, the control is simply unavailable once running.
    @Test("the chip disappears once the workout has started")
    func noChipOnceRunning() {
        #expect(!display(coaching: .beginner, started: true).showsCoachingChip)
    }

    @Test("the ticker shows only when there is a call")
    func tickerVisibility() {
        #expect(display(started: true, call: nil).currentCall == nil)
        let call = CoachCallDisplay(primary: "Jab", secondary: "1", modifier: nil)
        #expect(display(started: true, call: call).currentCall?.primary == "Jab")
    }

    @Test("the minimal preference is carried to the view")
    func minimalIsCarried() {
        #expect(display(minimal: true).isMinimalScreen)
        #expect(!display(minimal: false).isMinimalScreen)
    }

    /// The preference only means anything during a coached round — there is nothing to strip back to
    /// when there is no ticker to keep.
    @Test("minimal applies only when a coached round is running")
    func minimalOnlyWhenCoached() {
        let call = CoachCallDisplay(primary: "Jab", secondary: nil, modifier: nil)
        #expect(display(coaching: .beginner, started: true, call: call, minimal: true).hidesSecondaryDetail)
        #expect(!display(coaching: nil, started: true, call: nil, minimal: true).hidesSecondaryDetail)
        #expect(!display(coaching: .beginner, started: false, minimal: true).hidesSecondaryDetail)
    }
}

@MainActor
@Suite("What minimal actually hides")
struct MinimalScreenContentTests {
    private func display(minimal: Bool, coached: Bool = true, started: Bool = true) -> WorkoutDisplayModel {
        let call = CoachCallDisplay(primary: "Jab Cross", secondary: "1 · 2", modifier: nil)
        let snapshot = WorkoutSnapshot(
            phase: .round(index: 3), remaining: .seconds(95), elapsedInPhase: .seconds(85),
            elapsedTotal: .seconds(560), totalDuration: .seconds(2830), roundCount: 12,
            isPaused: false, started: started, currentCall: coached ? call : nil)
        return WorkoutDisplayModel(snapshot, direction: .countDown, workoutType: .heavyBag,
                                   coachingLevel: coached ? .beginner : nil, minimalScreen: minimal)
    }

    /// Asserting the *effect*, not the flag. The first version of this feature set the flag
    /// correctly and hid almost nothing — the two rendered screens were near-identical, which only
    /// showed up in a snapshot.
    @Test("minimal keeps the time, the phase and the call")
    func keepsTheEssentials() {
        let minimal = display(minimal: true)
        #expect(minimal.timeLabel == "1:35")
        #expect(minimal.phaseLabel == "Round 3 / 12")
        #expect(minimal.currentCall?.primary == "Jab Cross")
    }

    @Test("minimal drops the total-remaining line, which normal keeps")
    func dropsTotalRemaining() {
        #expect(display(minimal: true).hidesSecondaryDetail)
        #expect(!display(minimal: false).hidesSecondaryDetail)
        // The label is still computed — the view decides not to draw it — so the two differ only
        // in what the screen shows, not in what the model knows.
        #expect(display(minimal: true).totalRemainingLabel == display(minimal: false).totalRemainingLabel)
    }

    @Test("an uncoached workout is never stripped, whatever the preference")
    func uncoachedIsUntouched() {
        #expect(!display(minimal: true, coached: false).hidesSecondaryDetail)
    }
}

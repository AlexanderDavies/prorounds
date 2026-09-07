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

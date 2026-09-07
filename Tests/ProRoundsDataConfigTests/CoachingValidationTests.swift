import Testing
import Foundation
import ProRoundsFoundationUtilities
@testable import ProRoundsDataConfig

@Suite("Coaching validation")
struct CoachingValidationTests {
    private func make(_ type: WorkoutType, coaching: CoachingLevel?, rounds: Int = 12) -> Configuration {
        Configuration(workoutType: type, rounds: rounds, roundDuration: .seconds(180),
                      restDuration: .seconds(60), prepDuration: .seconds(20),
                      warningLead: .seconds(10), coachingLevel: coaching)
    }

    @Test("coaching is valid for a scripted type", arguments: [WorkoutType.shadowBoxing, .heavyBag])
    func validForScriptedTypes(type: WorkoutType) {
        #expect(ConfigurationValidator.validate(make(type, coaching: .beginner)).isEmpty)
    }

    @Test("coaching is rejected for an unscripted type",
          arguments: [WorkoutType.skipping, .speedBall, .sparring])
    func rejectedForUnscriptedTypes(type: WorkoutType) {
        #expect(ConfigurationValidator.validate(make(type, coaching: .beginner))
            == [.coachingUnavailableForWorkoutType])
    }

    @Test("coaching off is valid for every type", arguments: WorkoutType.allCases)
    func offIsAlwaysValid(type: WorkoutType) {
        #expect(ConfigurationValidator.validate(make(type, coaching: nil)).isEmpty)
    }

    /// Consistent with the existing behaviour of reporting all violations together rather than
    /// stopping at the first.
    @Test("a coaching violation is reported alongside other violations")
    func reportedWithOthers() {
        let errors = ConfigurationValidator.validate(make(.skipping, coaching: .beginner, rounds: 0))
        #expect(errors.contains(.coachingUnavailableForWorkoutType))
        #expect(errors.contains(.roundCountTooLow))
    }

    /// The validator and the editor read one source, so they cannot disagree about what is
    /// offerable — a rule the UI contradicts is worse than no rule.
    @Test("validation agrees with supportsCoaching for every type", arguments: WorkoutType.allCases)
    func agreesWithTheSharedSource(type: WorkoutType) {
        let rejected = ConfigurationValidator.validate(make(type, coaching: .beginner))
            .contains(.coachingUnavailableForWorkoutType)
        #expect(rejected == !type.supportsCoaching)
    }
}

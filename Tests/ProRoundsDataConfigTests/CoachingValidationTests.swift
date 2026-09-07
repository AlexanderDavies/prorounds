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

@Suite("UI-test seeding carries coaching")
struct SeedCoachingTests {
    /// `ConfigurationStore.seed` is how the app plants a known configuration for the UI flow tests.
    /// If it dropped the coaching level, the coached UI test would exercise an uncoached workout and
    /// quietly prove nothing — so the round-trip is asserted here rather than through a simulator.
    @Test("a seeded coached configuration reads back coached")
    func seedPreservesCoaching() async throws {
        let container = try ConfigurationStore.makeContainer(inMemory: true)
        let seeded = Configuration(
            workoutType: .heavyBag, rounds: 3, roundDuration: .seconds(120),
            restDuration: .seconds(30), prepDuration: .seconds(5), warningLead: .seconds(10),
            customName: "UI Test Bag", coachingLevel: .beginner)
        await MainActor.run { ConfigurationStore.seed([seeded], into: container) }

        let repository = SwiftDataConfigurationRepository(modelContainer: container)
        let loaded = try #require(try await repository.all().first { $0.id == seeded.id })
        #expect(loaded.coachingLevel == .beginner)
        #expect(loaded.workoutType == .heavyBag)
        #expect(loaded.customName == "UI Test Bag")
    }

    @Test("a seeded uncoached configuration stays uncoached")
    func seedPreservesAbsence() async throws {
        let container = try ConfigurationStore.makeContainer(inMemory: true)
        let seeded = Configuration(
            workoutType: .heavyBag, rounds: 3, roundDuration: .seconds(120),
            restDuration: .seconds(30), prepDuration: .zero, warningLead: .zero)
        await MainActor.run { ConfigurationStore.seed([seeded], into: container) }
        let repository = SwiftDataConfigurationRepository(modelContainer: container)
        let loaded = try #require(try await repository.all().first { $0.id == seeded.id })
        #expect(loaded.coachingLevel == nil)
    }
}

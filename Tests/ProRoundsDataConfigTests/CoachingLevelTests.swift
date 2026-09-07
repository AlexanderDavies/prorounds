import Foundation
import Testing
import ProRoundsFoundationUtilities
@testable import ProRoundsDataConfig

@Suite("Coaching level")
struct CoachingLevelTests {
    @Test("beginner is the only level in v1")
    func onlyBeginner() {
        #expect(CoachingLevel.allCases == [.beginner])
    }

    /// The raw value is what gets persisted, so a rename is a silent data migration. Pinned here so
    /// it fails at the test rather than in someone's saved configurations.
    @Test("raw values are pinned, because they are what the store writes")
    func rawValuesArePinned() {
        #expect(CoachingLevel.beginner.rawValue == "beginner")
        #expect(CoachingLevel(rawValue: "beginner") == .beginner)
    }

    @Test("an unrecognised level does not decode")
    func unknownRawValue() {
        #expect(CoachingLevel(rawValue: "expert") == nil)
    }

    @Test("every level has a display name")
    func displayNames() {
        for level in CoachingLevel.allCases {
            #expect(!level.displayName.isEmpty)
        }
        #expect(CoachingLevel.beginner.displayName == "Beginner")
    }

    /// Coached variants inside `WorkoutType` were rejected outright: that enumeration is
    /// load-bearing across auto-naming, the session model and the chart legend, so adding a mode
    /// flag would reopen four shipped specs.
    @Test("coaching stayed out of WorkoutType")
    func workoutTypeIsUnchanged() {
        #expect(WorkoutType.allCases.count == 5)
        #expect(Set(WorkoutType.allCases.map(\.rawValue))
            == ["shadowBoxing", "skipping", "heavyBag", "speedBall", "sparring"])
    }

    @Test("only the workout types with an authored script support coaching")
    func supportedTypes() {
        #expect(WorkoutType.shadowBoxing.supportsCoaching)
        #expect(WorkoutType.heavyBag.supportsCoaching)
        #expect(!WorkoutType.skipping.supportsCoaching)
        #expect(!WorkoutType.speedBall.supportsCoaching)
        #expect(!WorkoutType.sparring.supportsCoaching)
    }
}

@Suite("Configuration carries a coaching level")
struct ConfigurationCoachingTests {
    private func make(coaching: CoachingLevel? = nil, type: WorkoutType = .shadowBoxing) -> Configuration {
        Configuration(
            workoutType: type, rounds: 12,
            roundDuration: .seconds(180), restDuration: .seconds(60),
            prepDuration: .seconds(20), warningLead: .seconds(10),
            coachingLevel: coaching)
    }

    @Test("coaching is off unless asked for")
    func defaultsToOff() {
        let configuration = Configuration(
            workoutType: .shadowBoxing, rounds: 3,
            roundDuration: .seconds(180), restDuration: .seconds(60),
            prepDuration: .seconds(20), warningLead: .seconds(10))
        #expect(configuration.coachingLevel == nil)
    }

    @Test("a coaching level is carried")
    func carriesLevel() {
        #expect(make(coaching: .beginner).coachingLevel == .beginner)
    }

    /// Coaching is not part of the workout's arithmetic or its identity as a workout. A coached and
    /// an uncoached 12x3:00 are the same workout, said differently.
    @Test("coaching does not change the total duration or the auto name")
    func derivedValuesAreUnaffected() {
        let coached = make(coaching: .beginner)
        let plain = make()
        #expect(coached.totalDuration == plain.totalDuration)
        #expect(coached.effectiveName == plain.effectiveName)
    }

    @Test("coaching participates in equality")
    func equality() {
        let identity = UUID()
        func build(_ level: CoachingLevel?) -> Configuration {
            Configuration(id: identity, workoutType: .shadowBoxing, rounds: 3,
                          roundDuration: .seconds(180), restDuration: .seconds(60),
                          prepDuration: .seconds(20), warningLead: .seconds(10),
                          coachingLevel: level)
        }
        #expect(build(.beginner) != build(nil))
        #expect(build(.beginner) == build(.beginner))
    }
}

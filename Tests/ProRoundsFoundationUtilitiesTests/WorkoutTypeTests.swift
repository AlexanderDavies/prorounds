import Testing
@testable import ProRoundsFoundationUtilities

@Suite("WorkoutType")
struct WorkoutTypeTests {
    @Test("The five types are listed in spec order")
    func orderMatchesSpec() {
        #expect(WorkoutType.allCases == [
            .shadowBoxing, .skipping, .heavyBag, .speedBall, .sparring
        ])
    }

    @Test("Display names match the product spec")
    func displayNames() {
        #expect(WorkoutType.shadowBoxing.displayName == "Shadow Boxing")
        #expect(WorkoutType.skipping.displayName == "Skipping")
        #expect(WorkoutType.heavyBag.displayName == "Heavy Bag")
        #expect(WorkoutType.speedBall.displayName == "Speed Ball")
        #expect(WorkoutType.sparring.displayName == "Sparring")
    }
}

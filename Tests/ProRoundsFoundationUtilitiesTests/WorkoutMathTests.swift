import Testing
import Foundation
@testable import ProRoundsFoundationUtilities

@Suite("WorkoutMath.totalDuration")
struct WorkoutMathTotalTests {
    @Test("Total is rounds + rest, excluding prep and rest after the final round")
    func roundsPlusRestOnly() {
        // 12 rounds of 3:00, 1:00 rest → 12×3:00 + 11×1:00 = 47:00 (prep excluded)
        let total = WorkoutMath.totalDuration(round: .seconds(180), rest: .seconds(60), rounds: 12)
        #expect(total == .seconds(12 * 180 + 11 * 60)) // 2820s = 47:00
    }

    @Test("A single round has no rest")
    func singleRoundNoRest() {
        let total = WorkoutMath.totalDuration(round: .seconds(120), rest: .seconds(30), rounds: 1)
        #expect(total == .seconds(120))
    }

    @Test("Zero rounds yields zero")
    func zeroRoundsIsZero() {
        let total = WorkoutMath.totalDuration(round: .seconds(180), rest: .seconds(60), rounds: 0)
        #expect(total == .zero)
    }

    @Test("Prep does not change the total")
    func prepIrrelevant() {
        // The calculator takes no prep argument — a workout's prep never affects its total.
        #expect(WorkoutMath.totalDuration(round: .seconds(180), rest: .seconds(60), rounds: 3)
                == .seconds(3 * 180 + 2 * 60))
    }
}

@Suite("WorkoutMath.autoName")
struct WorkoutMathAutoNameTests {
    @Test("Name is derived from configuration fields")
    func derivesName() {
        let name = WorkoutMath.autoName(
            workoutTypeName: "Heavy Bag",
            rounds: 12,
            round: .seconds(180),
            rest: .seconds(60)
        )
        #expect(name == "Heavy Bag · 12×3min / 1min rest")
    }

    @Test("Sub-minute rest renders as m:ss inside the name")
    func fractionalRestInName() {
        let name = WorkoutMath.autoName(
            workoutTypeName: "Quick Shadow",
            rounds: 3,
            round: .seconds(120),
            rest: .seconds(30)
        )
        #expect(name == "Quick Shadow · 3×2min / 0:30 rest")
    }
}

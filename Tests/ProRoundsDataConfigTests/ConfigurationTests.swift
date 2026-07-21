import Testing
import Foundation
@testable import ProRoundsDataConfig
import ProRoundsFoundationUtilities

@Suite("Configuration")
struct ConfigurationTests {
    private func make(rounds: Int = 12,
                      round: Duration = .seconds(180),
                      rest: Duration = .seconds(60),
                      prep: Duration = .seconds(10),
                      warningLead: Duration = .seconds(10),
                      type: WorkoutType = .heavyBag,
                      name: String? = nil) -> Configuration {
        Configuration(workoutType: type, rounds: rounds, roundDuration: round,
                      restDuration: rest, prepDuration: prep, warningLead: warningLead,
                      customName: name)
    }

    @Test("Total duration uses the single-source calculator (rounds + rest, prep excluded)")
    func totalDuration() {
        #expect(make().totalDuration == .seconds(12 * 180 + 11 * 60)) // 47:00, prep excluded
    }

    @Test("Effective name falls back to the auto name when no custom name")
    func autoName() {
        #expect(make(name: nil).effectiveName == "Heavy Bag · 12×3min / 1min rest")
    }

    @Test("Blank custom name still falls back to the auto name")
    func blankName() {
        #expect(make(name: "   ").effectiveName == "Heavy Bag · 12×3min / 1min rest")
    }

    @Test("Custom name is preserved")
    func customName() {
        #expect(make(name: "Heavy Bag Blast").effectiveName == "Heavy Bag Blast")
    }
}

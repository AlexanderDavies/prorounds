import Testing
import Foundation
@testable import ProRoundsDataConfig
import ProRoundsFoundationUtilities

@Suite("Configuration identity")
struct ConfigurationIdentityTests {
    @Test("A configuration built without an id gets a fresh unique id")
    func freshIdByDefault() {
        let first = Configuration(workoutType: .heavyBag, rounds: 3, roundDuration: .seconds(120),
                                  restDuration: .seconds(30), prepDuration: .zero, warningLead: .zero)
        let second = Configuration(workoutType: .heavyBag, rounds: 3, roundDuration: .seconds(120),
                                   restDuration: .seconds(30), prepDuration: .zero, warningLead: .zero)
        #expect(first.id != second.id)
    }

    @Test("An explicit id is preserved and derived values are unaffected")
    func explicitIdPreserved() {
        let id = UUID()
        let config = Configuration(id: id, workoutType: .heavyBag, rounds: 12, roundDuration: .seconds(180),
                                   restDuration: .seconds(60), prepDuration: .seconds(10), warningLead: .seconds(10))
        #expect(config.id == id)
        #expect(config.totalDuration == .seconds(12 * 180 + 11 * 60)) // 47:00, prep excluded
        #expect(config.effectiveName == "Heavy Bag · 12×3min / 1min rest")
    }
}

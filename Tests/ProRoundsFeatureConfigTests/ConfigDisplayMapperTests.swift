import Testing
import Foundation
@testable import ProRoundsFeatureConfig
import ProRoundsDataConfig
import ProRoundsFoundationUtilities

@Suite("ConfigDisplayMapper")
struct ConfigDisplayMapperTests {
    @Test("Maps a configuration to a formatted row")
    func mapsRow() {
        let config = ConfigTestSupport.config("Heavy Bag Blast")
        let row = ConfigDisplayMapper.row(config)
        #expect(row.id == config.id)
        #expect(row.name == "Heavy Bag Blast")
        #expect(row.metadata == "12 × 3:00 · 1:00 rest")
        #expect(row.totalText == "47:00") // rounds + rest, prep excluded
        #expect(row.iconSystemName == "figure.kickboxing")
    }

    @Test("Blank name maps to the auto-generated name")
    func autoName() {
        let row = ConfigDisplayMapper.row(ConfigTestSupport.config(nil))
        #expect(row.name == "Heavy Bag · 12×3min / 1min rest")
    }

    @Test("Each workout type has an icon")
    func icons() {
        for type in WorkoutType.allCases {
            #expect(!ConfigDisplayMapper.icon(for: type).isEmpty)
        }
    }
}

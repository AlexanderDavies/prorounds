import Testing
import Foundation
@testable import ProRoundsDataConfig
import ProRoundsFoundationUtilities

@Suite("ConfigurationMapper")
struct ConfigurationMapperTests {
    @Test("Entity → domain round-trips all fields")
    func toDomainRoundTrip() {
        let id = UUID()
        let entity = ConfigurationEntity(
            id: id, workoutTypeRaw: WorkoutType.heavyBag.rawValue, rounds: 12,
            roundSeconds: 180, restSeconds: 60, prepSeconds: 10, warningLeadSeconds: 10,
            customName: "Heavy Bag Blast", createdAt: .now, updatedAt: .now
        )
        let config = ConfigurationMapper.toDomain(entity)
        #expect(config.id == id)
        #expect(config.workoutType == .heavyBag)
        #expect(config.rounds == 12)
        #expect(config.roundDuration == .seconds(180))
        #expect(config.restDuration == .seconds(60))
        #expect(config.prepDuration == .seconds(10))
        #expect(config.warningLead == .seconds(10))
        #expect(config.customName == "Heavy Bag Blast")
    }

    @Test("Empty stored name maps to a nil custom name (auto-name applies)")
    func emptyNameBecomesNil() {
        let entity = ConfigurationEntity(
            id: UUID(), workoutTypeRaw: WorkoutType.skipping.rawValue, rounds: 3,
            roundSeconds: 120, restSeconds: 30, prepSeconds: 0, warningLeadSeconds: 0,
            customName: "", createdAt: .now, updatedAt: .now
        )
        let config = ConfigurationMapper.toDomain(entity)
        #expect(config.customName == nil)
    }

    @Test("Domain → entity writes seconds and empty-name for nil")
    func makeEntity() {
        let config = Configuration(workoutType: .sparring, rounds: 5, roundDuration: .seconds(90),
                                   restDuration: .seconds(45), prepDuration: .seconds(5),
                                   warningLead: .seconds(10), customName: nil)
        let entity = ConfigurationMapper.makeEntity(from: config, now: .now)
        #expect(entity.id == config.id)
        #expect(entity.workoutTypeRaw == "sparring")
        #expect(entity.roundSeconds == 90)
        #expect(entity.warningLeadSeconds == 10)
        #expect(entity.customName == "")
    }
}

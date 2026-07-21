import Testing
import Foundation
@testable import ProRoundsDataConfig
import ProRoundsFoundationUtilities

@Suite("SwiftDataConfigurationRepository")
struct ConfigurationRepositoryTests {
    private func makeRepository() throws -> SwiftDataConfigurationRepository {
        let container = try ConfigurationStore.makeContainer(inMemory: true)
        return SwiftDataConfigurationRepository(modelContainer: container)
    }

    private func config(_ name: String, rounds: Int = 3, id: UUID = UUID()) -> Configuration {
        Configuration(id: id, workoutType: .heavyBag, rounds: rounds, roundDuration: .seconds(180),
                      restDuration: .seconds(60), prepDuration: .seconds(10), warningLead: .seconds(10),
                      customName: name)
    }

    @Test("Saving a new configuration inserts it")
    func saveInserts() async throws {
        let repo = try makeRepository()
        try await repo.save(config("Alpha"))
        let all = try await repo.all()
        #expect(all.count == 1)
        #expect(all.first?.customName == "Alpha")
    }

    @Test("Saving an existing id updates in place, not a duplicate")
    func saveUpdatesInPlace() async throws {
        let repo = try makeRepository()
        let id = UUID()
        try await repo.save(config("Original", rounds: 3, id: id))
        try await repo.save(config("Renamed", rounds: 8, id: id))

        let all = try await repo.all()
        #expect(all.count == 1)
        #expect(all.first?.customName == "Renamed")
        #expect(all.first?.rounds == 8)
    }

    @Test("Deleting removes the configuration")
    func deleteRemoves() async throws {
        let repo = try makeRepository()
        let target = config("ToDelete")
        try await repo.save(target)
        try await repo.save(config("Keep"))
        try await repo.delete(target.id)

        let all = try await repo.all()
        #expect(all.count == 1)
        #expect(all.first?.customName == "Keep")
    }

    @Test("Deleting an absent id is a no-op")
    func deleteAbsentIsHarmless() async throws {
        let repo = try makeRepository()
        try await repo.save(config("Only"))
        try await repo.delete(UUID()) // not stored
        let all = try await repo.all()
        #expect(all.count == 1)
    }

    @Test("Listing is ordered most-recent-first")
    func listOrderedMostRecentFirst() async throws {
        let repo = try makeRepository()
        try await repo.save(config("First"))
        try await repo.save(config("Second"))
        let all = try await repo.all()
        #expect(all.map(\.customName) == ["Second", "First"])
    }
}

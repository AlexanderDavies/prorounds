import Testing
import Foundation
import SwiftData
import ProRoundsFoundationPersistence
import ProRoundsFoundationUtilities
@testable import ProRoundsDataConfig

/// The configuration store as it was *before* coaching existed.
///
/// This is the whole point of the test below. A migration fixture built from the current model
/// proves nothing — it would write the new shape and read the new shape. This writes the old shape,
/// so reopening it under the current schema exercises the real migration. The class name must match
/// the shipped entity's, because that is what SwiftData keys the stored entity on.
private enum LegacySchema {
    @Model
    final class ConfigurationEntity {
        @Attribute(.unique) var id: UUID
        var workoutTypeRaw: String
        var rounds: Int
        var roundSeconds: Int
        var restSeconds: Int
        var prepSeconds: Int
        var warningLeadSeconds: Int
        var customName: String
        var createdAt: Date
        var updatedAt: Date

        init(id: UUID, workoutTypeRaw: String, rounds: Int, roundSeconds: Int, restSeconds: Int,
             prepSeconds: Int, warningLeadSeconds: Int, customName: String,
             createdAt: Date, updatedAt: Date) {
            self.id = id
            self.workoutTypeRaw = workoutTypeRaw
            self.rounds = rounds
            self.roundSeconds = roundSeconds
            self.restSeconds = restSeconds
            self.prepSeconds = prepSeconds
            self.warningLeadSeconds = warningLeadSeconds
            self.customName = customName
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }
}

/// **Serialized on purpose.** `LegacySchema.ConfigurationEntity` deliberately shares its class name
/// with the shipped entity — that is what makes the fixture a real old store — but SwiftData keys
/// stored entities on that name, so two models claiming it must never be live at once. Overlapping
/// containers intermittently drop the newer column (a coached configuration reads back uncoached)
/// and can abort the whole test run.
@Suite("Migration from the pre-coaching store", .serialized)
struct ConfigurationMigrationTests {
    private struct Seed {
        let id = UUID()
        let type: WorkoutType
        let rounds: Int
        let name: String
    }

    private static let seeds = [
        Seed(type: .shadowBoxing, rounds: 12, name: "Old Shadow"),
        Seed(type: .heavyBag, rounds: 6, name: "Old Bag"),
        Seed(type: .skipping, rounds: 3, name: "")
    ]

    /// Writes a store with the legacy entity shape and returns its directory.
    private func writeLegacyStore() throws -> URL {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let container = try PersistenceContainer.make(
            for: [LegacySchema.ConfigurationEntity.self], directory: directory)
        let context = ModelContext(container)
        for seed in Self.seeds {
            context.insert(LegacySchema.ConfigurationEntity(
                id: seed.id, workoutTypeRaw: seed.type.rawValue, rounds: seed.rounds,
                roundSeconds: 180, restSeconds: 60, prepSeconds: 20, warningLeadSeconds: 10,
                customName: seed.name, createdAt: .now, updatedAt: .now))
        }
        try context.save()
        // Drop the legacy container before returning: its entity description must not be live when
        // a container for the shipped entity is created.
        return directory
    }

    @Test("a store written before coaching still opens, with every record intact")
    func legacyStoreOpens() async throws {
        let directory = try writeLegacyStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let container = try ConfigurationStore.makeContainer(directory: directory)
        let repository = SwiftDataConfigurationRepository(modelContainer: container)
        let all = try await repository.all()

        #expect(all.count == Self.seeds.count, "records were lost in migration")
        for seed in Self.seeds {
            let migrated = try #require(all.first { $0.id == seed.id }, "\(seed.name) was lost")
            #expect(migrated.workoutType == seed.type)
            #expect(migrated.rounds == seed.rounds)
            #expect(migrated.roundDuration == .seconds(180))
            #expect(migrated.restDuration == .seconds(60))
            #expect(migrated.prepDuration == .seconds(20))
            #expect(migrated.warningLead == .seconds(10))
        }
    }

    @Test("migrated records read back with coaching off, not with a default level")
    func migratedRecordsAreUncoached() async throws {
        let directory = try writeLegacyStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let container = try ConfigurationStore.makeContainer(directory: directory)
        let repository = SwiftDataConfigurationRepository(modelContainer: container)
        for configuration in try await repository.all() {
            #expect(configuration.coachingLevel == nil)
        }
    }

    @Test("a migrated record is still writable")
    func migratedRecordsAreWritable() async throws {
        let directory = try writeLegacyStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let container = try ConfigurationStore.makeContainer(directory: directory)
        let repository = SwiftDataConfigurationRepository(modelContainer: container)
        let original = try #require(try await repository.all().first { $0.workoutType == .shadowBoxing })

        let edited = Configuration(
            id: original.id, workoutType: original.workoutType, rounds: original.rounds,
            roundDuration: original.roundDuration, restDuration: original.restDuration,
            prepDuration: original.prepDuration, warningLead: original.warningLead,
            customName: "Now Coached", coachingLevel: .beginner)
        try await repository.save(edited)

        let reread = try #require(try await repository.all().first { $0.id == original.id })
        #expect(reread.customName == "Now Coached")
        #expect(reread.coachingLevel == .beginner)
    }
}

@Suite("Coaching persistence", .serialized)
struct CoachingPersistenceTests {
    private func make(_ level: CoachingLevel?) -> Configuration {
        Configuration(workoutType: .heavyBag, rounds: 5, roundDuration: .seconds(120),
                      restDuration: .seconds(45), prepDuration: .seconds(20),
                      warningLead: .seconds(10), coachingLevel: level)
    }

    /// The stored string, not the enum ordinal. Pinned because renaming the case would silently
    /// orphan every coached configuration already on someone's device.
    @Test("beginner persists as the exact string 'beginner'")
    func rawValueIsPinned() {
        let entity = ConfigurationMapper.makeEntity(from: make(.beginner), now: .now)
        #expect(entity.coachingLevelRaw == "beginner")
    }

    @Test("coaching off persists as nil, not an empty string")
    func offPersistsAsNil() {
        let entity = ConfigurationMapper.makeEntity(from: make(nil), now: .now)
        #expect(entity.coachingLevelRaw == nil)
    }

    /// Forward compatibility: a store written by a later build carrying a level this build does not
    /// know must still open, with that configuration simply uncoached.
    @Test("an unrecognised level degrades to coaching off")
    func unknownLevelDegrades() {
        let entity = ConfigurationMapper.makeEntity(from: make(.beginner), now: .now)
        entity.coachingLevelRaw = "expert"
        #expect(ConfigurationMapper.toDomain(entity).coachingLevel == nil)
    }

    @Test("an in-place update writes the coaching level through")
    func applyUpdatesCoaching() {
        let entity = ConfigurationMapper.makeEntity(from: make(.beginner), now: .now)
        ConfigurationMapper.apply(make(nil), to: entity, now: .now)
        #expect(entity.coachingLevelRaw == nil)
        ConfigurationMapper.apply(make(.beginner), to: entity, now: .now)
        #expect(entity.coachingLevelRaw == "beginner")
    }

    @Test("a coached configuration round-trips through the repository")
    func coachedRoundTrip() async throws {
        let container = try ConfigurationStore.makeContainer(inMemory: true)
        let repository = SwiftDataConfigurationRepository(modelContainer: container)
        let saved = make(.beginner)
        try await repository.save(saved)
        let loaded = try #require(try await repository.all().first { $0.id == saved.id })
        #expect(loaded.coachingLevel == .beginner)
    }

    @Test("an uncoached configuration round-trips as uncoached")
    func uncoachedRoundTrip() async throws {
        let container = try ConfigurationStore.makeContainer(inMemory: true)
        let repository = SwiftDataConfigurationRepository(modelContainer: container)
        let saved = make(nil)
        try await repository.save(saved)
        let loaded = try #require(try await repository.all().first { $0.id == saved.id })
        #expect(loaded.coachingLevel == nil)
    }
}

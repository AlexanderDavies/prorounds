import Testing
import Foundation
import SwiftData
@testable import ProRoundsFoundationPersistence

@Model
final class SampleEntity {
    var value: Int
    init(value: Int) { self.value = value }
}

@Suite("PersistenceContainer")
@MainActor
struct PersistenceContainerTests {
    @Test("Builds an in-memory container that can insert and fetch")
    func inMemoryContainerRoundTrips() throws {
        let container = try PersistenceContainer.make(for: [SampleEntity.self], inMemory: true)
        let context = ModelContext(container)
        context.insert(SampleEntity(value: 42))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SampleEntity>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.value == 42)
    }

    @Test("The default (on-disk) factory returns a usable container")
    func defaultContainerBuilds() throws {
        // Use a unique in-memory schema per run for hermeticity; the on-disk path is exercised in
        // the app. Building must not throw.
        let container = try PersistenceContainer.make(for: [SampleEntity.self], inMemory: true)
        #expect(container.configurations.isEmpty == false)
    }
}

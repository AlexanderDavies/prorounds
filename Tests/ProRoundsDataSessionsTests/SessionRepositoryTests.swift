import Testing
import Foundation
@testable import ProRoundsDataSessions
import ProRoundsFoundationUtilities

@Suite("SwiftDataSessionRepository")
struct SessionRepositoryTests {
    private func makeRepository() throws -> SwiftDataSessionRepository {
        SwiftDataSessionRepository(modelContainer: try SessionStore.makeContainer(inMemory: true))
    }

    @Test("Mapper round-trips a session")
    func mapperRoundTrip() {
        let session = SessionFixture.make()
        let restored = SessionMapper.toDomain(SessionMapper.makeEntity(from: session))
        #expect(restored == session)
    }

    @Test("Saving inserts and listing returns it as a domain value")
    func saveAndList() async throws {
        let repo = try makeRepository()
        try await repo.save(SessionFixture.make(name: "One"))
        let all = try await repo.all()
        #expect(all.count == 1)
        #expect(all.first?.configurationName == "One")
    }

    @Test("Listing is most-recent-first by date")
    func mostRecentFirst() async throws {
        let repo = try makeRepository()
        let base = Date(timeIntervalSince1970: 1_000_000)
        try await repo.save(SessionFixture.make(name: "Older", date: base))
        try await repo.save(SessionFixture.make(name: "Newer", date: base.addingTimeInterval(60)))
        let all = try await repo.all()
        #expect(all.map(\.configurationName) == ["Newer", "Older"])
    }

    @Test("byWorkoutType buckets sessions by their type")
    func groupedByType() async throws {
        let repo = try makeRepository()
        try await repo.save(SessionFixture.make(type: .heavyBag, name: "Bag"))
        try await repo.save(SessionFixture.make(type: .skipping, name: "Skip"))
        try await repo.save(SessionFixture.make(type: .heavyBag, name: "Bag2"))

        let grouped = try await repo.byWorkoutType()
        #expect(grouped[.heavyBag]?.count == 2)
        #expect(grouped[.skipping]?.count == 1)
        #expect(grouped[.sparring] == nil)
    }

    @Test("A saved session survives a fresh container (relaunch)")
    func survivesRelaunch() async throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let saved = SessionFixture.make(name: "Persisted")
        do {
            let repo = SwiftDataSessionRepository(modelContainer: try SessionStore.makeContainer(directory: directory))
            try await repo.save(saved)
        }
        let repo = SwiftDataSessionRepository(modelContainer: try SessionStore.makeContainer(directory: directory))
        #expect(try await repo.all().contains { $0.id == saved.id })
    }
}

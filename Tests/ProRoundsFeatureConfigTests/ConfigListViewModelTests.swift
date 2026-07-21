import Testing
import Foundation
@testable import ProRoundsFeatureConfig
import ProRoundsDataConfig

@MainActor
@Suite("ConfigListViewModel")
struct ConfigListViewModelTests {
    @Test("Loads configurations as rows, most-recent-first")
    func loadsRows() async throws {
        let repo = try ConfigTestSupport.makeRepository()
        try await repo.save(ConfigTestSupport.config("First"))
        try await repo.save(ConfigTestSupport.config("Second"))

        let model = ConfigListViewModel(repository: repo)
        await model.load()

        #expect(model.isLoaded)
        #expect(!model.isEmpty)
        #expect(model.rows.map(\.name) == ["Second", "First"])
    }

    @Test("Reports empty when there are no configurations")
    func emptyState() async throws {
        let model = ConfigListViewModel(repository: try ConfigTestSupport.makeRepository())
        await model.load()
        #expect(model.isEmpty)
        #expect(model.rows.isEmpty)
    }

    @Test("Delete removes the configuration and persists")
    func delete() async throws {
        let repo = try ConfigTestSupport.makeRepository()
        let target = ConfigTestSupport.config("Doomed")
        try await repo.save(target)
        try await repo.save(ConfigTestSupport.config("Keep"))

        let model = ConfigListViewModel(repository: repo)
        await model.load()
        await model.delete(id: target.id)

        #expect(model.rows.map(\.name) == ["Keep"])
        #expect(try await repo.all().count == 1)
    }

    @Test("Looks up the domain configuration by id for editing")
    func lookupById() async throws {
        let repo = try ConfigTestSupport.makeRepository()
        let target = ConfigTestSupport.config("Edit me")
        try await repo.save(target)

        let model = ConfigListViewModel(repository: repo)
        await model.load()
        #expect(model.configuration(id: target.id)?.customName == "Edit me")
        #expect(model.configuration(id: UUID()) == nil)
    }
}

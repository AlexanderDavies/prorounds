import Foundation
import SwiftData

/// The Data boundary for configurations (guide §6.1). Features depend on this protocol and work
/// only in domain `Configuration` values; the SwiftData entity and `ModelContext` never cross it.
public protocol ConfigurationRepository: Sendable {
    /// All configurations, most-recently-created-or-updated first.
    func all() async throws -> [Configuration]
    /// Insert a new configuration or update the existing one with the same id.
    func save(_ configuration: Configuration) async throws
    /// Remove the configuration with the given id; a missing id is a no-op.
    func delete(_ id: Configuration.ID) async throws
}

/// SwiftData-backed repository. A `@ModelActor` so it owns its (non-`Sendable`) `ModelContext` on an
/// actor and hands back only `Sendable` domain values. The container is injected (built by
/// `PersistenceContainer`), so config and later sessions can share one store.
@ModelActor
public actor SwiftDataConfigurationRepository: ConfigurationRepository {
    public func all() async throws -> [Configuration] {
        let descriptor = FetchDescriptor<ConfigurationEntity>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map(ConfigurationMapper.toDomain)
    }

    public func save(_ configuration: Configuration) async throws {
        let now = Date()
        if let existing = try fetchEntity(id: configuration.id) {
            ConfigurationMapper.apply(configuration, to: existing, now: now)
        } else {
            modelContext.insert(ConfigurationMapper.makeEntity(from: configuration, now: now))
        }
        try modelContext.save()
    }

    public func delete(_ id: Configuration.ID) async throws {
        guard let existing = try fetchEntity(id: id) else { return }
        modelContext.delete(existing)
        try modelContext.save()
    }

    private func fetchEntity(id: UUID) throws -> ConfigurationEntity? {
        var descriptor = FetchDescriptor<ConfigurationEntity>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}

import Foundation
import SwiftData
import ProRoundsFoundationPersistence

/// The SwiftData persistence record for a configuration. **Internal** — it never escapes the
/// repository; callers always work with the domain `Configuration` value type (guide §6.3).
/// Durations are stored as whole seconds (all product durations are whole seconds).
@Model
final class ConfigurationEntity {
    @Attribute(.unique) var id: UUID
    var workoutTypeRaw: String
    var rounds: Int
    var roundSeconds: Int
    var restSeconds: Int
    var prepSeconds: Int
    var warningLeadSeconds: Int
    /// Empty string means "no custom name" (the effective name is auto-generated).
    var customName: String
    /// Store-internal ordering timestamps — not exposed on the domain model.
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        workoutTypeRaw: String,
        rounds: Int,
        roundSeconds: Int,
        restSeconds: Int,
        prepSeconds: Int,
        warningLeadSeconds: Int,
        customName: String,
        createdAt: Date,
        updatedAt: Date
    ) {
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

/// The DataConfig entity types, exposed type-erased so the composition root and tests can build a
/// container for them without `ConfigurationEntity` becoming public (guide §6.2 / layering).
public enum ConfigurationStore {
    public static let models: [any PersistentModel.Type] = [ConfigurationEntity.self]

    /// Convenience for a config-only container (tests, or a config-only composition). A shared store
    /// across features is built at the composition root from each store's `models`.
    public static func makeContainer(inMemory: Bool = false, directory: URL? = nil) throws -> ModelContainer {
        try PersistenceContainer.make(for: models, inMemory: inMemory, directory: directory)
    }

    /// Synchronously inserts configurations into a container — for UI-test seeding at launch, so a
    /// known configuration is present before the list loads.
    @MainActor
    public static func seed(_ configurations: [Configuration], into container: ModelContainer) {
        let context = ModelContext(container)
        let now = Date()
        for configuration in configurations {
            context.insert(ConfigurationMapper.makeEntity(from: configuration, now: now))
        }
        try? context.save()
    }
}

import Foundation
import SwiftData

/// The single place the SwiftData `ModelContainer` is configured (guide §6.2). It is **generic** in
/// its entity types — the caller (the composition root, or a test) passes the `@Model` types — so
/// this Foundation-layer module holds no reference to a Data-layer entity and the layering stays
/// intact. Repositories receive a container built here; no feature builds one elsewhere.
public enum PersistenceContainer {
    /// Builds a container for the given models. `inMemory` yields a memory-only store (tests);
    /// otherwise the on-device store is used — at `directory` when provided (a temp dir keeps
    /// on-disk persistence tests hermetic), else SwiftData's default location.
    public static func make(
        for models: [any PersistentModel.Type],
        inMemory: Bool = false,
        directory: URL? = nil
    ) throws -> ModelContainer {
        let schema = Schema(models)
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else if let directory {
            configuration = ModelConfiguration(schema: schema, url: directory.appending(path: "prorounds.store"))
        } else {
            configuration = ModelConfiguration(schema: schema)
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

import Foundation
import SwiftData
import ProRoundsFoundationPersistence

/// The SwiftData record for a completed workout. **Internal** — it never escapes the repository
/// (guide §6.3). Durations are stored as whole seconds.
@Model
final class SessionEntity {
    @Attribute(.unique) var id: UUID
    var date: Date
    var workoutTypeRaw: String
    var configurationName: String
    var rounds: Int
    var roundSeconds: Int
    var restSeconds: Int
    var prepSeconds: Int
    var roundsCompleted: Int
    var totalSeconds: Int

    init(
        id: UUID,
        date: Date,
        workoutTypeRaw: String,
        configurationName: String,
        rounds: Int,
        roundSeconds: Int,
        restSeconds: Int,
        prepSeconds: Int,
        roundsCompleted: Int,
        totalSeconds: Int
    ) {
        self.id = id
        self.date = date
        self.workoutTypeRaw = workoutTypeRaw
        self.configurationName = configurationName
        self.rounds = rounds
        self.roundSeconds = roundSeconds
        self.restSeconds = restSeconds
        self.prepSeconds = prepSeconds
        self.roundsCompleted = roundsCompleted
        self.totalSeconds = totalSeconds
    }
}

/// The DataSessions entity types, exposed type-erased so the composition root and tests build a
/// container without `SessionEntity` becoming public (guide §6.2 / layering).
public enum SessionStore {
    public static let models: [any PersistentModel.Type] = [SessionEntity.self]

    public static func makeContainer(inMemory: Bool = false, directory: URL? = nil) throws -> ModelContainer {
        try PersistenceContainer.make(for: models, inMemory: inMemory, directory: directory)
    }
}

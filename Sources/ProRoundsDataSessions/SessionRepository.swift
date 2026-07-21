import Foundation
import SwiftData
import ProRoundsFoundationUtilities

/// The Data boundary for sessions (guide §6.1). Features depend on this protocol and work only in
/// domain `Session` values. `byWorkoutType()` groups for the performance chart so the view doesn't
/// regroup.
public protocol SessionRepository: Sendable {
    func save(_ session: Session) async throws
    /// All sessions, most-recent-first.
    func all() async throws -> [Session]
    /// Sessions grouped by workout type.
    func byWorkoutType() async throws -> [WorkoutType: [Session]]
}

/// SwiftData-backed session repository — a `@ModelActor` owning its context; sessions are append-only
/// records (save inserts). The container is injected (shared with the config store).
@ModelActor
public actor SwiftDataSessionRepository: SessionRepository {
    public func save(_ session: Session) async throws {
        modelContext.insert(SessionMapper.makeEntity(from: session))
        try modelContext.save()
    }

    public func all() async throws -> [Session] {
        let descriptor = FetchDescriptor<SessionEntity>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map(SessionMapper.toDomain)
    }

    public func byWorkoutType() async throws -> [WorkoutType: [Session]] {
        Dictionary(grouping: try await all(), by: \.workoutType)
    }
}

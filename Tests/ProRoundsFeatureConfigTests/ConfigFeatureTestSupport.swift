import Foundation
import ProRoundsDataConfig
import ProRoundsFoundationUtilities

/// Builds a repository backed by an in-memory store (guide §5.5) — the test seam for the config
/// view models.
enum ConfigTestSupport {
    static func makeRepository() throws -> SwiftDataConfigurationRepository {
        let container = try ConfigurationStore.makeContainer(inMemory: true)
        return SwiftDataConfigurationRepository(modelContainer: container)
    }

    static func config(
        _ name: String? = nil,
        type: WorkoutType = .heavyBag,
        rounds: Int = 12,
        round: Duration = .seconds(180),
        rest: Duration = .seconds(60),
        prep: Duration = .seconds(10),
        lead: Duration = .seconds(10),
        id: UUID = UUID()
    ) -> Configuration {
        Configuration(id: id, workoutType: type, rounds: rounds, roundDuration: round,
                      restDuration: rest, prepDuration: prep, warningLead: lead, customName: name)
    }
}

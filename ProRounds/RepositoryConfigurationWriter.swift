import ProRoundsDataConfig
import ProRoundsFeatureTimer

/// Narrows the configuration repository to the one operation the workout screen may perform.
///
/// The running screen edits the coaching level, which must write the same stored value the editor
/// writes — but it has no business listing or deleting configurations. Adapting here rather than
/// widening `ConfigurationWriting` keeps that limit in the type system, and adapting a wide
/// protocol to a narrow one is exactly the composition root's job (guide §5).
struct RepositoryConfigurationWriter: ConfigurationWriting {
    let repository: any ConfigurationRepository

    func save(_ configuration: Configuration) async throws {
        try await repository.save(configuration)
    }
}

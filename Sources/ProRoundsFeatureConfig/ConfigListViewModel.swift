import Foundation
import Observation
import ProRoundsDataConfig

/// View model for the Configurations list (guide §3.2). Owns the loaded configurations, exposes
/// pre-mapped rows, and forwards delete intents to the repository. No formatting or persistence
/// logic beyond delegating to the repository.
@MainActor
@Observable
public final class ConfigListViewModel {
    public private(set) var isLoaded = false
    private(set) var configurations: [Configuration] = []

    private let repository: any ConfigurationRepository

    public init(repository: any ConfigurationRepository) {
        self.repository = repository
    }

    var rows: [ConfigRowDisplay] { configurations.map(ConfigDisplayMapper.row) }

    var isEmpty: Bool { isLoaded && configurations.isEmpty }

    func configuration(id: Configuration.ID) -> Configuration? {
        configurations.first { $0.id == id }
    }

    func load() async {
        configurations = (try? await repository.all()) ?? []
        isLoaded = true
    }

    func delete(id: Configuration.ID) async {
        try? await repository.delete(id)
        await load()
    }
}

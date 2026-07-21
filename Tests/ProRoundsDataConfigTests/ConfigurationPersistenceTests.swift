import Testing
import Foundation
@testable import ProRoundsDataConfig
import ProRoundsFoundationUtilities

@Suite("On-disk persistence")
struct ConfigurationPersistenceTests {
    @Test("A configuration saved on disk is read back by a fresh container (survives relaunch)")
    func survivesNewContainer() async throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let saved = Configuration(workoutType: .heavyBag, rounds: 7, roundDuration: .seconds(120),
                                  restDuration: .seconds(45), prepDuration: .seconds(5),
                                  warningLead: .seconds(10), customName: "On Disk")

        // First "launch": write.
        do {
            let container = try ConfigurationStore.makeContainer(directory: directory)
            let repo = SwiftDataConfigurationRepository(modelContainer: container)
            try await repo.save(saved)
        }

        // Second "launch": a fresh container at the same location reads it back.
        let container = try ConfigurationStore.makeContainer(directory: directory)
        let repo = SwiftDataConfigurationRepository(modelContainer: container)
        let all = try await repo.all()
        #expect(all.contains { $0.id == saved.id && $0.customName == "On Disk" && $0.rounds == 7 })
    }
}

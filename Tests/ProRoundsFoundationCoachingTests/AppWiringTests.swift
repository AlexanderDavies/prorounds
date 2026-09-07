import Testing
import Foundation
@testable import ProRoundsFoundationCoaching

@Suite("App wiring")
struct AppWiringTests {
    private func repoRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }

    /// The catalog and both scripts must resolve from the module bundle, which is what the app will
    /// do at runtime once a coached workout starts.
    @Test("the catalog and both scripts load from the module bundle")
    func contentLoadsFromBundle() throws {
        let catalog = try CoachCatalog.bundled()
        #expect(catalog.phrases.count == 89)
        for name in CoachScript.bundledNames {
            #expect(try CoachScript.bundled(name).segments.count == 4)
        }
        #expect(try CoachValidator.validateBundled().isValid)
    }

    /// The composition root is the only place an entitlement store is built (guide §5). A feature
    /// constructing its own would defeat the seam — swapping the implementation would then mean
    /// hunting call sites rather than editing one file.
    @Test("only the composition root constructs an entitlement store")
    func onlyTheRootConstructsOne() throws {
        let root = repoRoot()
        var offenders: [String] = []
        for directory in ["Sources", "ProRounds"] {
            let base = root.appendingPathComponent(directory)
            guard let walker = FileManager.default.enumerator(atPath: base.path) else { continue }
            for case let path as String in walker where path.hasSuffix(".swift") {
                // The seam's own definition site is allowed to name its implementations.
                if path.hasSuffix("EntitlementStore.swift") { continue }
                let file = base.appendingPathComponent(path)
                guard let text = try? String(contentsOf: file, encoding: .utf8) else { continue }
                if text.contains("UnlockedEntitlementStore()"), !path.contains("AppEnvironment") {
                    offenders.append("\(directory)/\(path)")
                }
            }
        }
        #expect(offenders.isEmpty, "constructed outside the composition root: \(offenders)")
    }

    @Test("the app target links the coaching module")
    func appLinksCoaching() throws {
        let manifest = try String(
            contentsOf: repoRoot().appendingPathComponent("project.yml"), encoding: .utf8)
        #expect(manifest.contains("ProRoundsFoundationCoaching"))
    }
}

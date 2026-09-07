import Testing
import Foundation

/// Guards the module layering declared in `docs/ARCHITECTURE_GUIDE.md` §2.1:
/// **Foundation ← Data ← Feature**, with DesignSystem available to Data and Feature, and no Feature
/// depending on a sibling Feature.
///
/// This exists because the layering is **not** enforced by the compiler. SwiftPM permits a target to
/// import any other target in the same package, whether or not it declares the dependency —
/// verified directly: `ProRoundsFeatureTimer` can `import ProRoundsFeaturePerformance` and build,
/// which is the one thing the guide forbids outright. So the rule is checked here, against the
/// manifest, or it is not checked at all.
@Suite("Module layering")
struct ModuleLayeringTests {
    private enum Layer: String {
        case foundation = "Foundation"
        case designSystem = "DesignSystem"
        case data = "Data"
        case feature = "Feature"

        /// Which layers a module here may depend on. A Feature may reach Data, Foundation and the
        /// design system — but never a sibling Feature, which is why that case is handled separately.
        var mayDependOn: Set<Layer> {
            switch self {
            case .foundation: return [.foundation]
            case .designSystem: return [.foundation]
            case .data: return [.foundation, .designSystem]
            case .feature: return [.foundation, .designSystem, .data]
            }
        }
    }

    private struct Module {
        let name: String
        let dependencies: [String]
        let layer: Layer
    }

    private static func layer(of name: String) -> Layer? {
        guard name.hasPrefix("ProRounds") else { return nil }
        if name == "ProRoundsDesignSystem" { return .designSystem }
        for candidate: Layer in [.foundation, .data, .feature]
        where name.hasPrefix("ProRounds\(candidate.rawValue)") {
            return candidate
        }
        return nil
    }

    /// Parses the non-test targets and their in-package dependencies out of `Package.swift`.
    private func modules() throws -> [Module] {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let manifest = try String(
            contentsOf: root.appendingPathComponent("Package.swift"), encoding: .utf8)

        var found: [Module] = []
        // `.testTarget(` does not match: the capital T means the literal ".target(" is absent.
        for chunk in manifest.components(separatedBy: ".target(name: \"").dropFirst() {
            guard let name = chunk.split(separator: "\"", maxSplits: 1).first.map(String.init),
                  let layer = Self.layer(of: name) else { continue }
            found.append(Module(name: name, dependencies: dependencies(in: chunk), layer: layer))
        }
        return found
    }

    /// In-package dependency names from a target's `dependencies: [...]` list. `.product(...)`
    /// entries are external packages and are not layered.
    private func dependencies(in chunk: String) -> [String] {
        guard let start = chunk.range(of: "dependencies: [") else { return [] }
        let rest = chunk[start.upperBound...]
        guard let end = rest.firstIndex(of: "]") else { return [] }
        return rest[..<end]
            .components(separatedBy: "\"")
            .filter { Self.layer(of: $0) != nil }
    }

    @Test("the manifest is parsed — every shipped module is found")
    func manifestParses() throws {
        let found = try modules()
        #expect(found.count >= 13, "found only \(found.count) modules; the parser is likely broken")
        #expect(found.contains { $0.name == "ProRoundsFeatureTimer" })
        #expect(found.contains { $0.name == "ProRoundsFoundationCoaching" })
        // A parser that found no dependencies anywhere would pass every rule below vacuously.
        #expect(found.contains { !$0.dependencies.isEmpty })
    }

    @Test("no module depends on a layer above it")
    func layeringIsRespected() throws {
        for module in try modules() {
            for dependency in module.dependencies {
                guard let dependencyLayer = Self.layer(of: dependency) else { continue }
                let detail = "\(module.name) (\(module.layer.rawValue)) depends on "
                    + "\(dependency) (\(dependencyLayer.rawValue)), which its layer may not reach"
                #expect(module.layer.mayDependOn.contains(dependencyLayer), "\(detail)")
            }
        }
    }

    /// The rule the guide states most plainly, and the one the compiler does not enforce: a Feature
    /// reaching a sibling Feature couples two screens that should only meet at the composition root.
    @Test("no Feature depends on a sibling Feature")
    func featuresAreSiblings() throws {
        for module in try modules() where module.layer == .feature {
            for dependency in module.dependencies where Self.layer(of: dependency) == .feature {
                Issue.record("\(module.name) depends on sibling Feature \(dependency)")
            }
        }
    }

    /// Every in-package module a target imports must also be declared as its dependency.
    ///
    /// Added after exactly this slipped through: `ProRoundsFoundationCoaching` imported
    /// `ProRoundsFoundationAudio` without declaring it, `swift test` compiled it happily, and the
    /// failure only surfaced when `xcodebuild` built the app for a simulator — "unable to resolve
    /// module dependency". The layering rules above check declared edges, so an *undeclared* edge
    /// is invisible to them; this closes that gap and keeps the manifest an honest description of
    /// what each module actually uses.
    @Test("every imported in-package module is a declared dependency")
    func importsAreDeclared() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        for module in try modules() {
            let directory = root.appendingPathComponent("Sources/\(module.name)")
            guard let walker = FileManager.default.enumerator(atPath: directory.path) else { continue }
            let declared = Set(module.dependencies)
            for case let path as String in walker where path.hasSuffix(".swift") {
                let file = directory.appendingPathComponent(path)
                guard let source = try? String(contentsOf: file, encoding: .utf8) else { continue }
                for line in source.split(separator: "\n") where line.hasPrefix("import ProRounds") {
                    let imported = String(line.dropFirst("import ".count))
                        .trimmingCharacters(in: .whitespaces)
                    guard imported != module.name else { continue }
                    #expect(declared.contains(imported),
                            "\(module.name)/\(path) imports \(imported) without declaring it")
                }
            }
        }
    }

    /// Foundation is the floor. A Foundation module reaching Data or a Feature would invert the
    /// graph and make the lower layers untestable in isolation.
    @Test("Foundation modules depend only on Foundation")
    func foundationIsSelfContained() throws {
        for module in try modules() where module.layer == .foundation {
            for dependency in module.dependencies {
                #expect(Self.layer(of: dependency) == .foundation,
                        "\(module.name) reaches \(dependency), which is not Foundation")
            }
        }
    }
}

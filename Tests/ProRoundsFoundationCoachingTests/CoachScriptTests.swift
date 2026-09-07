import Testing
import Foundation
@testable import ProRoundsFoundationCoaching

@Suite("Script decoding")
struct CoachScriptTests {
    @Test("both beginner scripts decode", arguments: ["beginner_shadow", "beginner_bag"])
    func scriptsDecode(name: String) throws {
        let script = try CoachScript.bundled(name)
        #expect(script.segments.map(\.id) == ["open", "build", "work", "finish"])
        #expect(abs(script.segments.reduce(0) { $0 + $1.share } - 1.0) < 1e-9)
    }

    @Test("guards decode with their per-kind no-repeat windows")
    func guardsDecode() throws {
        let script = try CoachScript.bundled("beginner_shadow")
        #expect(script.guards.roundStartDelayMs == 1500)
        #expect(script.guards.roundEndGuardMs == 2000)
        #expect(script.guards.warningGuardMs == 750)
        #expect(script.guards.minGapMs == 1200)
        #expect(script.guards.maxConsecutiveNonCombo == 2)
        #expect(script.guards.followsBoost == 3)
        #expect(script.guards.answerAfterNonCombo)
        #expect(script.guards.noRepeatWithinKind[.technique] == 6)
        #expect(script.guards.noRepeatWithinKind[.movement] == 2)
    }

    @Test("segments carry cadence, mix and weighted pools")
    func segmentsDecode() throws {
        let open = try #require(try CoachScript.bundled("beginner_shadow").segments.first)
        #expect(open.cadenceMs == 8000...10000)
        #expect(open.mix[.combo] == 0.4)
        #expect(open.mix[.effort] == 0)
        let combos = try #require(open.pools[.combo])
        #expect(combos.first?.id == "jab")
        #expect(combos.first?.weight == 6)
    }

    @Test("pinned cues decode with their offset from the round end")
    func pinnedDecode() throws {
        let script = try CoachScript.bundled("beginner_shadow")
        let pinned = script.segments.flatMap(\.pinned)
        let lastTen = try #require(pinned.first { $0.id == "effort_last_ten" })
        #expect(lastTen.atFromRoundEndMs == 10000)
    }

    /// `voice`, `intent`, `why` and `note` describe what a segment is *for*, so a later script is
    /// written to the same shape. They are never spoken, and are not decoded at all — speaking one
    /// is structurally impossible rather than merely discouraged.
    @Test("author notes are present in the JSON but absent from the domain types")
    func authorNotesAreNotSpeakable() throws {
        let url = try #require(CoachingBundle.resources.url(
            forResource: "beginner_shadow", withExtension: "json"))
        let raw = try #require(String(data: Data(contentsOf: url), encoding: .utf8))
        #expect(raw.contains("\"intent\""), "fixture should carry author notes to make this meaningful")

        let catalog = try CoachCatalog.bundled()
        let spoken = Set(catalog.order.compactMap { catalog[$0] }
            .flatMap { [$0.text.spoken(.numbers), $0.text.spoken(.names)] })
        let script = try CoachScript.bundled("beginner_shadow")
        for segment in script.segments {
            #expect(!spoken.contains(segment.id), "segment id leaked into speakable text")
        }
        // Every speakable string comes from the catalog's `text`, nowhere else.
        #expect(spoken.allSatisfy { !$0.isEmpty })
    }
}

@Suite("Catalog and script integrity")
struct CoachValidationTests {
    @Test("the shipped catalog and both scripts validate clean")
    func shippedContentIsValid() throws {
        let report = try CoachValidator.validateBundled()
        #expect(report.errors.isEmpty, "errors: \(report.errors.map(\.description))")
    }

    @Test("an unknown phrase in a pool is rejected and named")
    func unknownPoolPhrase() throws {
        let catalog = try CoachCatalog.bundled()
        var script = try CoachScript.bundled("beginner_shadow")
        script.segments[0].pools[.combo]?.append(PoolEntry(id: "no_such_phrase", weight: 1))
        let errors = CoachValidator.validate(script: script, against: catalog)
        #expect(errors.contains { $0.description.contains("no_such_phrase") })
    }

    @Test("a no-repeat window as large as its pool is rejected")
    func windowCannotExceedPool() throws {
        let catalog = try CoachCatalog.bundled()
        var script = try CoachScript.bundled("beginner_shadow")
        let poolSize = script.segments[0].pools[.movement]?.count ?? 0
        script.guards.noRepeatWithinKind[.movement] = poolSize
        let errors = CoachValidator.validate(script: script, against: catalog)
        #expect(errors.contains { $0.description.contains("no-repeat window") })
    }

    @Test("segment shares that do not sum to 1 are rejected")
    func sharesMustSumToOne() throws {
        let catalog = try CoachCatalog.bundled()
        var script = try CoachScript.bundled("beginner_shadow")
        script.segments[0].share += 0.1
        let errors = CoachValidator.validate(script: script, against: catalog)
        #expect(errors.contains { $0.description.contains("shares") })
    }

    @Test("a pool entry filed under the wrong kind is rejected")
    func poolKindMismatch() throws {
        let catalog = try CoachCatalog.bundled()
        var script = try CoachScript.bundled("beginner_shadow")
        script.segments[0].pools[.combo]?.append(PoolEntry(id: "tech_chin_down", weight: 1))
        let errors = CoachValidator.validate(script: script, against: catalog)
        #expect(errors.contains { $0.description.contains("tech_chin_down") })
    }

    @Test("a non-positive weight is rejected")
    func nonPositiveWeight() throws {
        let catalog = try CoachCatalog.bundled()
        var script = try CoachScript.bundled("beginner_shadow")
        script.segments[0].pools[.combo]?.append(PoolEntry(id: "jab_hook", weight: 0))
        let errors = CoachValidator.validate(script: script, against: catalog)
        #expect(errors.contains { $0.description.contains("weight") })
    }

    @Test("a combo declaring follows is rejected")
    func combosCannotFollow() throws {
        let json = Data("""
        {"version":1,"level":"beginner","phrases":[
          {"id":"c","kind":"combo","clip":"shared","tags":["jab"],"estMs":500,
           "follows":["jab"],"text":"One","ticker":{"line":"1"}}]}
        """.utf8)
        let catalog = try CoachCatalog(data: json)
        #expect(CoachValidator.validate(catalog: catalog).contains {
            $0.description.contains("follows")
        })
    }

    @Test("a follows tag no phrase produces is rejected")
    func unanswerableFollowsTag() throws {
        let json = Data("""
        {"version":1,"level":"beginner","phrases":[
          {"id":"t","kind":"technique","clip":"shared","tags":[],"estMs":500,
           "follows":["uppercut"],"text":"x","ticker":{"line":"x"}}]}
        """.utf8)
        let catalog = try CoachCatalog(data: json)
        #expect(CoachValidator.validate(catalog: catalog).contains {
            $0.description.contains("uppercut")
        })
    }
}

@Suite("Bundled content matches the authoring copy")
struct CatalogDriftTests {
    /// `docs/coaching/` is the authoring home; the package ships a copy. If the two drift, the app
    /// speaks something the authoring tools never validated.
    @Test("bundled phrases.json is byte-identical to docs/coaching/phrases.json")
    func noDrift() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ProRoundsFoundationCoachingTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // repo root
        let authored = repoRoot.appendingPathComponent("docs/coaching/phrases.json")
        guard FileManager.default.fileExists(atPath: authored.path) else { return }

        for name in ["phrases", "beginner_shadow", "beginner_bag"] {
            let bundledURL = try #require(CoachingBundle.resources.url(
                forResource: name, withExtension: "json"))
            let authoredURL = repoRoot.appendingPathComponent("docs/coaching/\(name).json")
            #expect(try Data(contentsOf: bundledURL) == (try Data(contentsOf: authoredURL)),
                    "\(name).json has drifted from docs/coaching/")
        }
    }
}

@Suite("Validator parity with the Python reference")
struct ValidatorParityTests {
    /// `scripts/coach-script.py validate` reports 0 errors and 0 warnings for the shipped content.
    /// The Swift port must agree — a port that finds nothing because it checks nothing would
    /// otherwise pass the suite above.
    @Test("Swift agrees with Python: no errors and no warnings")
    func matchesReferenceCounts() throws {
        let report = try CoachValidator.validateBundled()
        #expect(report.errors.isEmpty, "errors: \(report.errors.map(\.description))")
        #expect(report.warnings.isEmpty, "warnings: \(report.warnings.map(\.description))")
        #expect(report.isValid)
    }
}

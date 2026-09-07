import Testing
import Foundation
import ProRoundsFoundationAudio
import ProRoundsFoundationUtilities
@testable import ProRoundsFoundationCoaching

@Suite("Coach cue planner")
struct CoachCuePlannerTests {
    private func planner(
        type: WorkoutType = .shadowBoxing,
        convention: NamingConvention = .numbers,
        entitled: Bool = true,
        configID: String = "cfg"
    ) throws -> any RoundCuePlanning {
        try CoachCuePlanner.make(
            workoutType: type, configID: configID, convention: convention,
            warningMs: 10_000, entitlement: FixedEntitlementStore(isCoachingEntitled: entitled))
    }

    @Test("a coached workout plans calls")
    func plansCalls() throws {
        let plan = try planner().cues(forRound: 0, length: .seconds(180))
        #expect(!plan.isEmpty)
        #expect(plan.allSatisfy { if case .spoken = $0.cue { return true } else { return false } })
    }

    @Test("cues come back in ascending offset order")
    func ordered() throws {
        let plan = try planner().cues(forRound: 0, length: .seconds(180))
        #expect(plan.map(\.offset) == plan.map(\.offset).sorted())
    }

    @Test("both scripted workout types plan", arguments: [WorkoutType.shadowBoxing, .heavyBag])
    func bothScriptedTypesPlan(type: WorkoutType) throws {
        #expect(!(try planner(type: type).cues(forRound: 0, length: .seconds(180)).isEmpty))
    }

    /// Validation already prevents saving this, but a stored record must never crash a workout —
    /// so an unscripted type plans nothing rather than failing.
    @Test("a workout type with no script plans nothing",
          arguments: [WorkoutType.skipping, .speedBall, .sparring])
    func unscriptedTypesPlanNothing(type: WorkoutType) throws {
        #expect(try planner(type: type).cues(forRound: 0, length: .seconds(180)).isEmpty)
    }

    /// The locked path IS the uncoached path: an empty plan, not a special case in timing code.
    @Test("a locked entitlement plans nothing")
    func lockedPlansNothing() throws {
        #expect(try planner(entitled: false).cues(forRound: 0, length: .seconds(180)).isEmpty)
    }

    @Test("the plan is deterministic in configuration and round")
    func deterministic() throws {
        let first = try planner().cues(forRound: 2, length: .seconds(180))
        let again = try planner().cues(forRound: 2, length: .seconds(180))
        #expect(first == again)
    }

    @Test("different rounds plan differently")
    func roundsDiffer() throws {
        let one = try planner().cues(forRound: 0, length: .seconds(180))
        let two = try planner().cues(forRound: 1, length: .seconds(180))
        #expect(one != two)
    }

    @Test("different configurations plan differently")
    func configurationsDiffer() throws {
        let one = try planner(configID: "a").cues(forRound: 0, length: .seconds(180))
        let two = try planner(configID: "b").cues(forRound: 0, length: .seconds(180))
        #expect(one != two)
    }

    @Test("the convention selects the clip", arguments: [NamingConvention.numbers, .names])
    func conventionSelectsClip(convention: NamingConvention) throws {
        let plan = try planner(convention: convention).cues(forRound: 0, length: .seconds(180))
        let forked = plan.compactMap { planned -> URL? in
            guard case .spoken(let url) = planned.cue else { return nil }
            return url.deletingLastPathComponent().lastPathComponent == convention.rawValue ? url : nil
        }
        #expect(!forked.isEmpty, "no clip resolved through the \(convention.rawValue) folder")
    }

    @Test("shared phrases resolve to the shared folder whatever the convention")
    func sharedIgnoresConvention() throws {
        for convention in NamingConvention.allCases {
            let plan = try planner(convention: convention).cues(forRound: 0, length: .seconds(180))
            let folders = Set(plan.compactMap { planned -> String? in
                guard case .spoken(let url) = planned.cue else { return nil }
                return url.deletingLastPathComponent().lastPathComponent
            })
            #expect(folders.subtracting([convention.rawValue, "shared"]).isEmpty,
                    "unexpected folders \(folders)")
        }
    }

    @Test("every planned cue resolves to a clip that exists")
    func everyClipExists() throws {
        for plan in try [planner().cues(forRound: 0, length: .seconds(180)),
                         planner(type: .heavyBag).cues(forRound: 1, length: .seconds(240))] {
            for planned in plan {
                guard case .spoken(let url) = planned.cue else { continue }
                #expect(FileManager.default.fileExists(atPath: url.path), "missing \(url.lastPathComponent)")
            }
        }
    }

    /// The ticker is the whole channel for a deaf or hard-of-hearing user, so no cue may reach the
    /// timeline without text to show.
    @Test("every planned cue carries ticker text")
    func everyCueHasTickerText() throws {
        for planned in try planner().cues(forRound: 0, length: .seconds(180)) {
            #expect(!planned.tickerPrimary.isEmpty)
        }
    }

    @Test("a punch call carries both conventions, a spoken line carries one")
    func tickerShapes() throws {
        let plan = try planner().cues(forRound: 0, length: .seconds(180))
        #expect(plan.contains { $0.tickerSecondary != nil }, "expected at least one punch call")
        #expect(plan.contains { $0.tickerSecondary == nil }, "expected at least one single-line call")
    }
}

@Suite("Script availability is a single source")
struct ScriptAvailabilityTests {
    /// `WorkoutType.supportsCoaching` in the data layer and the scripts actually shipped here must
    /// agree. If a script is added for a new type and the flag is not updated, the editor would
    /// keep hiding a feature that works — so the two are compared rather than trusted.
    @Test("the shipped scripts match the types the app offers coaching for")
    func scriptsMatchTheOfferedTypes() throws {
        var scripted: Set<String> = []
        for name in CoachScript.bundledNames {
            scripted.insert(try CoachScript.bundled(name).workoutType)
        }
        #expect(scripted == ["shadowBoxing", "heavyBag"])
    }
}

@Suite("Coaching degrades rather than failing")
struct CoachPlannerDegradationTests {
    /// A bundle with no coaching resources — what a botched build or a stripped asset looks like.
    private var emptyBundle: Bundle { Bundle(for: BundleMarker.self) }
    private final class BundleMarker {}

    @Test("a missing catalog throws from make")
    func makeThrowsWithoutACatalog() {
        #expect(throws: (any Error).self) {
            try CoachCuePlanner.make(
                workoutType: .shadowBoxing, configID: "cfg", convention: .numbers,
                warningMs: 10_000, entitlement: UnlockedEntitlementStore(), bundle: emptyBundle)
        }
    }

    /// The rule that matters at launch: a content problem must never cost the user their timer.
    @Test("a missing catalog degrades to silence, not a crash")
    func degradesToSilence() {
        let planner = CoachCuePlanner.makeOrSilent(
            workoutType: .shadowBoxing, configID: "cfg", convention: .numbers,
            warningMs: 10_000, entitlement: UnlockedEntitlementStore(), bundle: emptyBundle)
        #expect(planner.cues(forRound: 0, length: .seconds(180)).isEmpty)
    }

    @Test("with the real bundle, makeOrSilent still plans")
    func realBundleStillPlans() {
        let planner = CoachCuePlanner.makeOrSilent(
            workoutType: .shadowBoxing, configID: "cfg", convention: .numbers,
            warningMs: 10_000, entitlement: UnlockedEntitlementStore())
        #expect(!planner.cues(forRound: 0, length: .seconds(180)).isEmpty)
    }
}

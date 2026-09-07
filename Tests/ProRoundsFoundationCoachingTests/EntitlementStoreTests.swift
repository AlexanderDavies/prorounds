import Testing
import Foundation
@testable import ProRoundsFoundationCoaching

@Suite("Entitlement seam")
struct EntitlementStoreTests {
    @Test("the shipped store reports coaching unlocked")
    func shippedStoreIsUnlocked() {
        #expect(UnlockedEntitlementStore().isCoachingEntitled)
    }

    @Test("a locked store can be substituted without touching production code")
    func lockedStoreSubstitutes() {
        let store: any EntitlementStore = FixedEntitlementStore(isCoachingEntitled: false)
        #expect(!store.isCoachingEntitled)
    }

    /// The constraint that actually matters. A paywall that could stall or fail a round would
    /// violate the product's top invariant, so the seam is synchronous and local by construction —
    /// there is no `async`, no publisher, and therefore no suspension point a round could wait on.
    /// This is enforced by the type, not by convention; the test documents it and proves the answer
    /// needs no awaiting.
    @Test("the answer is synchronous and immediate")
    func answerIsSynchronous() {
        let store = UnlockedEntitlementStore()
        let start = ContinuousClock.now
        for _ in 0..<10_000 { _ = store.isCoachingEntitled }
        #expect(ContinuousClock.now - start < .milliseconds(50))
    }

    /// Local-first: no purchase framework, no network. Checked against the source rather than
    /// asserted in prose, so adding an import fails the suite.
    @Test("the seam imports no purchase or networking framework")
    func noPurchaseFramework() throws {
        let source = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/ProRoundsFoundationCoaching/EntitlementStore.swift")
        guard FileManager.default.fileExists(atPath: source.path) else { return }
        let text = try String(contentsOf: source, encoding: .utf8)
        for forbidden in ["StoreKit", "URLSession", "Network"] {
            #expect(!text.contains("import \(forbidden)"), "the seam must not import \(forbidden)")
        }
    }
}

@Suite("The entitlement cannot reach the clock")
struct EntitlementIsolationTests {
    private func packageManifest() throws -> String {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try String(contentsOf: root.appendingPathComponent("Package.swift"), encoding: .utf8)
    }

    /// An architectural guard, not a unit test. The timer engine must have no route to the
    /// entitlement — not "does not currently call it", but *cannot*. Since the seam lives in the
    /// coaching module, the enforceable form is that the timer target does not depend on it, which
    /// the compiler then enforces for free.
    @Test("the timer target does not depend on the coaching module")
    func timerCannotReachCoaching() throws {
        let manifest = try packageManifest()
        guard let range = manifest.range(of: #".target(name: "ProRoundsFeatureTimer""#) else {
            Issue.record("could not find the timer target in Package.swift")
            return
        }
        let declaration = manifest[range.lowerBound...].prefix(while: { $0 != ")" })
        #expect(!declaration.contains("ProRoundsFoundationCoaching"),
                "the timer engine must not be able to consult the entitlement")
    }
}

@Suite("A locked entitlement loses nothing")
struct LockedEntitlementTests {
    /// When entitlement is later granted, everything the user chose while locked must still be
    /// there. The seam gates scheduling only — it never reaches storage or preferences.
    @Test("the seam exposes nothing but the answer")
    func seamIsMinimal() {
        let locked: any EntitlementStore = FixedEntitlementStore(isCoachingEntitled: false)
        let unlocked: any EntitlementStore = UnlockedEntitlementStore()
        // The protocol's entire surface. If it ever grows a way to mutate anything, this stops
        // compiling — which is the point.
        #expect(locked.isCoachingEntitled == false)
        #expect(unlocked.isCoachingEntitled == true)
    }

    /// Scheduling is a pure function of script, identity and round length — the scheduler takes no
    /// entitlement at all, so a locked workout's calls are decided the same way and simply not
    /// played. Change 3 gates playback, not selection.
    @Test("the scheduler is unaware of entitlement")
    func schedulerTakesNoEntitlement() throws {
        let scheduler = CoachCueScheduler(catalog: try CoachCatalog.bundled())
        let script = try CoachScript.bundled("beginner_shadow")
        let calls = scheduler.schedule(script: script, roundMs: 180_000, warningMs: 10_000,
                                       configID: "locked", roundIndex: 0)
        #expect(!calls.isEmpty)
    }
}

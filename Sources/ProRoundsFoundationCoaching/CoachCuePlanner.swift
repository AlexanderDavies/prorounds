import Foundation
import ProRoundsFoundationAudio
import ProRoundsFoundationUtilities

/// Turns a coached round into cues the timer can fire.
///
/// This is the only place the catalog, the scheduler, the naming convention, the clips and the
/// entitlement meet. Everything downstream — the engine, the running screen — sees only resolved
/// offsets, URLs and strings, which is what keeps the timer module free of any coaching dependency
/// and therefore unable to reach the entitlement.
public struct CoachCuePlanner: RoundCuePlanning {
    private let catalog: CoachCatalog
    private let script: CoachScript
    private let scheduler: CoachCueScheduler
    private let configID: String
    private let convention: NamingConvention
    private let warningMs: Int
    private let bundle: Bundle

    /// Builds a planner for a workout, or a planner that plans nothing.
    ///
    /// Returns the no-op planner when coaching is not entitled, or when the workout type has no
    /// authored script. Validation already prevents saving the latter, but a stored record must
    /// never be able to crash a workout — so it degrades rather than throwing.
    public static func make(
        workoutType: WorkoutType,
        configID: String,
        convention: NamingConvention,
        warningMs: Int,
        entitlement: any EntitlementStore,
        bundle: Bundle = CoachingBundle.resources
    ) throws -> any RoundCuePlanning {
        guard entitlement.isCoachingEntitled else { return NoRoundCuePlanner() }
        let catalog = try CoachCatalog.bundled(bundle)
        for name in CoachScript.bundledNames {
            let script = try CoachScript.bundled(name, bundle)
            guard script.workoutType == workoutType.rawValue else { continue }
            return CoachCuePlanner(
                catalog: catalog, script: script, configID: configID, convention: convention,
                warningMs: warningMs, bundle: bundle)
        }
        return NoRoundCuePlanner()
    }

    /// The same as `make`, but a catalog that cannot be loaded yields a planner that plans nothing
    /// rather than throwing.
    ///
    /// The composition root uses this: a content problem must never cost the user their timer. The
    /// degradation lives here rather than as a `try?` at the call site so it is covered by tests —
    /// the app target is not compiled by the package suite at all.
    public static func makeOrSilent(
        workoutType: WorkoutType,
        configID: String,
        convention: NamingConvention,
        warningMs: Int,
        entitlement: any EntitlementStore,
        bundle: Bundle = CoachingBundle.resources
    ) -> any RoundCuePlanning {
        (try? make(workoutType: workoutType, configID: configID, convention: convention,
                   warningMs: warningMs, entitlement: entitlement, bundle: bundle))
            ?? NoRoundCuePlanner()
    }

    init(
        catalog: CoachCatalog, script: CoachScript, configID: String,
        convention: NamingConvention, warningMs: Int, bundle: Bundle
    ) {
        self.catalog = catalog
        self.script = script
        self.scheduler = CoachCueScheduler(catalog: catalog)
        self.configID = configID
        self.convention = convention
        self.warningMs = warningMs
        self.bundle = bundle
    }

    public func cues(forRound round: Int, length: Duration) -> [PlannedCue] {
        let roundMs = Int(length.components.seconds) * 1000
        return scheduler
            .schedule(script: script, roundMs: roundMs, warningMs: warningMs,
                      configID: configID, roundIndex: round)
            .compactMap(planned(from:))
    }

    /// A call with no clip is dropped rather than played as silence or crashed on. The clips are
    /// derived artefacts that a regeneration could rename; losing one call is a far better failure
    /// than losing the round.
    private func planned(from cue: ScheduledCue) -> PlannedCue? {
        guard let phrase = catalog[cue.phraseID],
              let clip = phrase.clipURL(for: convention, in: bundle) else { return nil }
        let ticker = phrase.ticker
        return PlannedCue(
            offset: .milliseconds(cue.offsetMs),
            cue: .spoken(clip),
            // Names read large and numbers small above them, per the settled mockup: showing both
            // at once is what teaches the mapping passively, and it is the whole channel for
            // someone who cannot hear the call.
            tickerPrimary: ticker.primary(.names),
            tickerSecondary: isDualConvention(ticker) ? ticker.primary(.numbers) : nil,
            tickerModifier: ticker.modifier)
    }

    private func isDualConvention(_ ticker: CoachTicker) -> Bool {
        if case .punches = ticker { return true }
        return false
    }
}

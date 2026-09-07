import Foundation

/// A cue to fire at a position within a round, with everything the UI needs already resolved.
///
/// The display strings are carried here on purpose. If the running screen had to look a cue up to
/// render it, the presentation layer would need the module the cue came from — and the point of this
/// type is that the timer knows nothing about where its cues originate.
public struct PlannedCue: Equatable, Sendable {
    /// Position within the round, measured from its start. **Not** a delay to wait out: only
    /// something that already knows when the round began can interpret it, which is the engine.
    public let offset: Duration
    public let cue: AudioCue
    /// The line the running screen shows most prominently.
    public let tickerPrimary: String
    /// A second rendering of the same call, shown smaller — the other naming convention.
    public let tickerSecondary: String?
    /// A qualifier shown beneath, kept separate so the view can set it apart.
    public let tickerModifier: String?

    public init(
        offset: Duration,
        cue: AudioCue,
        tickerPrimary: String,
        tickerSecondary: String? = nil,
        tickerModifier: String? = nil
    ) {
        self.offset = offset
        self.cue = cue
        self.tickerPrimary = tickerPrimary
        self.tickerSecondary = tickerSecondary
        self.tickerModifier = tickerModifier
    }
}

/// Supplies the extra cues a round should fire.
///
/// This is the seam that lets coaching reach the timeline without the timer module learning what
/// coaching is. The engine asks for a round's cues, fires them from the same monotonic-deadline
/// arithmetic it uses for its own, and never inspects them.
///
/// Deliberately expressed as **offsets within a round**. A second scheduler running alongside the
/// engine — its own timer, its own sleeps — would be a second timeline, drifting independently and
/// failing quietly rather than crashing. There is one clock, and this protocol has no way to
/// introduce another.
public protocol RoundCuePlanning: Sendable {
    /// Cues for `round` (zero-based), in ascending offset order.
    func cues(forRound round: Int, length: Duration) -> [PlannedCue]
}

/// Plans nothing. The default, so an uncoached workout takes exactly the same code path as a coached
/// one rather than branching around the feature.
public struct NoRoundCuePlanner: RoundCuePlanning {
    public init() {}
    public func cues(forRound round: Int, length: Duration) -> [PlannedCue] { [] }
}

/// A fixed plan, for driving the engine's tests without a catalog.
public struct FixedRoundCuePlanner: RoundCuePlanning {
    private let plan: [PlannedCue]

    public init(cues: [PlannedCue]) {
        self.plan = cues.sorted { $0.offset < $1.offset }
    }

    public func cues(forRound round: Int, length: Duration) -> [PlannedCue] { plan }
}

import Foundation

/// One coaching call, placed relative to the start of its round.
public struct ScheduledCue: Sendable, Equatable {
    /// Milliseconds from round start.
    public let offsetMs: Int
    public let phraseID: String
    public let kind: CoachKind
}

extension ScheduledCue: Comparable {
    /// Python sorts the combined `(offset, id, kind)` tuples, so ties break on phrase id and then
    /// kind. No fixture currently contains two calls at the same offset — a tie needs a pinned cue
    /// to land exactly on a drawn one — so this ordering is asserted directly rather than left to
    /// be covered incidentally.
    public static func < (lhs: ScheduledCue, rhs: ScheduledCue) -> Bool {
        (lhs.offsetMs, lhs.phraseID, lhs.kind.rawValue)
            < (rhs.offsetMs, rhs.phraseID, rhs.kind.rawValue)
    }
}

/// Rounds half-to-even, matching Python's `round()`.
///
/// Swift's `rounded()` defaults to half-away-from-zero, so a naive port would disagree on an exact
/// `.5`. Measured, not assumed: exact `.5` never actually arises from the cadence walk — 0 across
/// 212,748 pre-rounding values — so this is insurance rather than a live bug, and it is unit-tested
/// directly because no fixture can reach it.
func roundedOffset(_ value: Double) -> Int {
    Int(value.rounded(.toNearestOrEven))
}

/// Turns a script plus a round's identity into the calls the coach makes.
///
/// Pure and deterministic: no clock, no I/O, no shared state. It is an **output** of the round
/// timer, never an input — it cannot move a phase boundary, change a round count, or delay the
/// bell. A whole round is returned at once rather than exposed as a cursor, so determinism is
/// trivially assertable and change 3 can hand the offsets straight to the existing
/// monotonic-deadline cue mechanism.
///
/// This is a port of `schedule()` in `scripts/coach-script.py`, which is normative. Statement order,
/// the `Double` walk, and the iteration order of pools are all load-bearing for byte-identity;
/// `Tests/.../Fixtures/schedules/` pins the result across 48 rounds.
public struct CoachCueScheduler: Sendable {
    private let catalog: CoachCatalog

    public init(catalog: CoachCatalog) {
        self.catalog = catalog
    }

    public func schedule(
        script: CoachScript,
        roundMs: Int,
        warningMs: Int,
        configID: String,
        roundIndex: Int
    ) -> [ScheduledCue] {
        var rng = SplitMix64(configID: configID, roundIndex: roundIndex)
        let round = RoundContext(roundMs: roundMs, warningMs: warningMs, guards: script.guards)
        let placement = placePinned(script: script, round: round)

        var state = SelectionState(pinned: placement.cues)
        var calls: [ScheduledCue] = []
        var segmentStart = 0.0

        for (index, segment) in script.segments.enumerated() {
            let segmentEnd = segmentStart + segment.share * Double(roundMs)
            var time = index == 0
                ? max(segmentStart, Double(round.guards.roundStartDelayMs))
                : segmentStart

            while time < segmentEnd {
                guard let pick = nextCall(in: segment, at: time, round: round,
                                          state: state, rng: &rng) else { break }

                var start = round.nudge(time)
                for reserved in placement.reserved
                where start < reserved.upperBound
                    && start + Double(pick.phrase.estMs) > reserved.lowerBound {
                    start = reserved.upperBound
                }
                // Still speaking at the bell — drop it rather than truncate or shift past.
                if start + Double(pick.phrase.estMs) > round.lastEnd {
                    time = segmentEnd
                    break
                }

                calls.append(ScheduledCue(offsetMs: roundedOffset(start),
                                          phraseID: pick.phrase.id, kind: pick.kind))
                state.record(pick.phrase, as: pick.kind)
                time = start + max(round.interval(for: segment, rng: &rng),
                                   Double(pick.phrase.estMs + round.guards.minGapMs))
            }
            segmentStart = segmentEnd
        }
        return (calls + placement.cues).sorted()
    }

    /// Draws the next kind, then the phrase within it — the whole selection half of one step.
    private func nextCall(
        in segment: CoachSegment, at time: Double, round: RoundContext,
        state: SelectionState, rng: inout SplitMix64
    ) -> (phrase: CoachPhrase, kind: CoachKind)? {
        let available = CoachKind.allCases.filter {
            (segment.mix[$0] ?? 0) > 0 && !(segment.pools[$0] ?? []).isEmpty
        }
        guard var kind = weightedChoice(available, using: &rng, weight: { segment.mix[$0] ?? 0 })
        else { return nil }

        // Never the same non-combo kind twice running, and never a third non-combo in a row — but
        // defence → technique IS allowed, because that pairing is what `follows` exists for.
        if kind != .combo, !(segment.pools[.combo] ?? []).isEmpty,
           kind == state.previousKind
            || state.consecutiveNonCombo >= round.guards.maxConsecutiveNonCombo {
            kind = .combo
        }

        let remaining = Double(round.roundMs) - time
        var pool = eligible(segment.pools[kind] ?? [], kind: kind, round: round,
                            state: state, remaining: remaining)

        // After a defence or movement call, a technique cue must *answer* it when one can:
        // "Roll left" → "Roll from the legs". This is what makes the coach sound like it is
        // watching you rather than reading a list.
        if kind == .technique, let previous = state.previousKind, previous != .combo,
           round.guards.answerAfterNonCombo {
            let answering = pool.filter { !(catalog[$0.entry.id]?.follows ?? []).isEmpty }
            if !answering.isEmpty { pool = answering }
        }
        if pool.isEmpty, kind != .combo {
            kind = .combo
            pool = eligible(segment.pools[.combo] ?? [], kind: .combo, round: round,
                            state: state, remaining: remaining)
        }
        if pool.isEmpty {
            pool = (segment.pools[kind] ?? []).map { (entry: $0, weight: $0.weight) }
        }
        guard let chosen = weightedChoice(pool, using: &rng, weight: { $0.weight })?.entry,
              let phrase = catalog[chosen.id]
        else { return nil }
        return (phrase, kind)
    }

    /// Pinned calls are placed before anything is drawn; drawn calls flow around them.
    private func placePinned(
        script: CoachScript, round: RoundContext
    ) -> (cues: [ScheduledCue], reserved: [Range<Double>]) {
        let roundMs = round.roundMs
        var cues: [ScheduledCue] = []
        var reserved: [Range<Double>] = []
        var segmentStart = 0.0
        for segment in script.segments {
            let segmentEnd = segmentStart + segment.share * Double(roundMs)
            for pin in segment.pinned {
                let at = round.nudge(Double(roundMs - pin.atFromRoundEndMs))
                guard let phrase = catalog[pin.id] else { continue }
                // Too short for this cue to be honest — drop it rather than distort the schedule.
                guard at >= segmentStart, at + Double(phrase.estMs) <= round.lastEnd else { continue }
                cues.append(ScheduledCue(offsetMs: roundedOffset(at), phraseID: pin.id, kind: phrase.kind))
                let gap = Double(round.guards.minGapMs)
                reserved.append((at - gap) ..< (at + Double(phrase.estMs) + gap))
            }
            segmentStart = segmentEnd
        }
        return (cues, reserved)
    }

    /// Candidates that survive the per-kind no-repeat window, their end-of-round window, and the
    /// `follows` requirement — with the boost applied to a cue that answers the previous call.
    private func eligible(
        _ entries: [PoolEntry], kind: CoachKind, round: RoundContext,
        state: SelectionState, remaining: Double
    ) -> [(entry: PoolEntry, weight: Double)] {
        let window = round.guards.noRepeatWithinKind[kind] ?? 0
        let history = state.recent[kind] ?? []
        let seen = window > 0 ? Set(history.suffix(window)) : []

        return entries.compactMap { entry in
            guard let phrase = catalog[entry.id], !seen.contains(entry.id) else { return nil }
            if let bounds = phrase.windowFromRoundEndMs,
               !(Double(bounds.lowerBound) <= remaining && remaining <= Double(bounds.upperBound)) {
                return nil
            }
            guard !phrase.follows.isEmpty else { return (entry, entry.weight) }
            // A cue that answers the last call is worth more.
            guard !state.previousTags.isDisjoint(with: phrase.follows) else { return nil }
            return (entry, entry.weight * round.guards.followsBoost)
        }
    }
}

/// The fixed facts of one round: everything derived from its length and guards.
private struct RoundContext {
    let roundMs: Int
    let guards: CoachGuards
    /// When the round-end warning cue fires, or nil when warnings are off.
    let warnAt: Double?
    /// Nothing may still be speaking after this.
    let lastEnd: Double

    init(roundMs: Int, warningMs: Int, guards: CoachGuards) {
        self.roundMs = roundMs
        self.guards = guards
        self.warnAt = warningMs > 0 ? Double(roundMs - warningMs) : nil
        self.lastEnd = Double(roundMs - guards.roundEndGuardMs)
    }

    /// Push a call clear of the round-end warning cue.
    func nudge(_ start: Double) -> Double {
        guard let warnAt, abs(start - warnAt) < Double(guards.warningGuardMs) else { return start }
        return warnAt + Double(guards.warningGuardMs)
    }

    /// Call start to call start, drawn uniformly from the segment's range.
    func interval(for segment: CoachSegment, rng: inout SplitMix64) -> Double {
        let low = Double(segment.cadenceMs.lowerBound)
        let high = Double(segment.cadenceMs.upperBound)
        return low + rng.unit() * (high - low)
    }
}

/// What the walk remembers between calls.
private struct SelectionState {
    /// Kept PER KIND: a technique cue waits for N other *technique* cues, not N calls. Counting
    /// across all calls let the same reminder land three times a round.
    var recent: [CoachKind: [String]]
    var previousTags: Set<String> = []
    var previousKind: CoachKind?
    var consecutiveNonCombo = 0

    init(pinned: [ScheduledCue]) {
        recent = Dictionary(uniqueKeysWithValues: CoachKind.allCases.map { ($0, []) })
        for cue in pinned { recent[cue.kind, default: []].append(cue.phraseID) }
    }

    mutating func record(_ phrase: CoachPhrase, as kind: CoachKind) {
        recent[kind, default: []].append(phrase.id)
        previousTags = Set(phrase.tags)
        previousKind = kind
        consecutiveNonCombo = kind == .combo ? 0 : consecutiveNonCombo + 1
    }
}

import Foundation

/// One weighted candidate in a segment's pool for a kind.
public struct PoolEntry: Sendable, Equatable {
    public let id: String
    public let weight: Double

    public init(id: String, weight: Double) {
        self.id = id
        self.weight = weight
    }
}

/// A cue placed before anything is drawn, at a fixed distance from the round end.
///
/// A coach always calls the last ten seconds; it is too important to leave to the draw.
public struct PinnedCue: Sendable, Equatable {
    public let id: String
    public let atFromRoundEndMs: Int
}

/// The timing rules a script schedules within.
public struct CoachGuards: Sendable, Equatable {
    /// No call starts before this, so the round-start bell is not spoken over.
    public var roundStartDelayMs: Int
    /// No call may still be speaking inside this window before the bell.
    public var roundEndGuardMs: Int
    /// Calls stay this far clear of the round-end warning cue.
    public var warningGuardMs: Int
    /// Silence between the end of one call and the start of the next.
    public var minGapMs: Int
    /// Never this many non-combo calls in a row.
    public var maxConsecutiveNonCombo: Int
    /// Draw-weight multiplier for a cue whose `follows` tags match the previous call.
    public var followsBoost: Double
    public var answerAfterNonCombo: Bool
    /// Counted **per kind**: a technique cue waits for N other *technique* cues, not N calls.
    public var noRepeatWithinKind: [CoachKind: Int]
}

/// One arc segment of a round — open, build, work, finish.
public struct CoachSegment: Sendable, Equatable {
    public let id: String
    /// Proportional, so one script serves any round length. Shares sum to 1.
    public var share: Double
    /// Call start to call start, drawn uniformly. The real gap is `max(drawn, estMs + minGapMs)`.
    public var cadenceMs: ClosedRange<Int>
    /// A **draw weight, not the delivered share** — adjacency rules convert some draws to combos.
    public var mix: [CoachKind: Double]
    public var pools: [CoachKind: [PoolEntry]]
    public var pinned: [PinnedCue]
}

/// A coach script: the pools and rules for one workout type at one level.
public struct CoachScript: Sendable, Equatable {
    public let id: String
    public let workoutType: String
    public var guards: CoachGuards
    public var segments: [CoachSegment]

    public init(data: Data) throws {
        let raw = try JSONDecoder().decode(RawScript.self, from: data)
        self.id = raw.id
        self.workoutType = raw.workoutType
        self.guards = CoachGuards(
            roundStartDelayMs: raw.guards.roundStartDelayMs,
            roundEndGuardMs: raw.guards.roundEndGuardMs,
            warningGuardMs: raw.guards.warningGuardMs,
            minGapMs: raw.guards.minGapMs,
            maxConsecutiveNonCombo: raw.guards.maxConsecutiveNonCombo,
            followsBoost: raw.guards.followsBoost ?? 1,
            answerAfterNonCombo: raw.guards.answerAfterNonCombo ?? false,
            noRepeatWithinKind: Self.byKind(raw.guards.noRepeatWithinKind))
        self.segments = try raw.segments.map { segment in
            guard segment.cadenceMs.count == 2 else {
                throw CoachCatalogError.malformedPhrase(
                    id: segment.id, reason: "cadenceMs must be [lo, hi]")
            }
            return CoachSegment(
                id: segment.id,
                share: segment.share,
                // Clamped so a reversed range cannot trap at construction; the validator reports it.
                cadenceMs: segment.cadenceMs[0]...max(segment.cadenceMs[0], segment.cadenceMs[1]),
                mix: Self.byKind(segment.mix),
                pools: Self.byKind(segment.pools.mapValues { $0.map { PoolEntry(id: $0.id, weight: $0.weight) } }),
                pinned: (segment.pinned ?? []).map { PinnedCue(id: $0.id, atFromRoundEndMs: $0.atFromRoundEndMs) })
        }
        self.rawCadence = raw.segments.map { ($0.id, $0.cadenceMs) }
    }

    /// Kept so the validator can report a reversed cadence range that the clamp above hides.
    let rawCadence: [(String, [Int])]

    public static func bundled(
        _ name: String,
        _ bundle: Bundle = CoachingBundle.resources
    ) throws -> CoachScript {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw CoachCatalogError.resourceMissing("\(name).json")
        }
        return try CoachScript(data: Data(contentsOf: url))
    }

    public static let bundledNames = ["beginner_shadow", "beginner_bag"]

    private static func byKind<Value>(_ raw: [String: Value]) -> [CoachKind: Value] {
        Dictionary(uniqueKeysWithValues: raw.compactMap { key, value in
            CoachKind(rawValue: key).map { ($0, value) }
        })
    }

    public static func == (lhs: CoachScript, rhs: CoachScript) -> Bool {
        lhs.id == rhs.id && lhs.workoutType == rhs.workoutType
            && lhs.guards == rhs.guards && lhs.segments == rhs.segments
    }
}

// MARK: - Wire format
//
// `voice`, `intent`, `why` and `note` are author notes — they say what a segment is for so the next
// script is written to the same shape. They are deliberately not decoded: leaving them out makes
// speaking one structurally impossible rather than merely discouraged.

private struct RawScript: Decodable {
    let id: String
    let workoutType: String
    let guards: RawGuards
    let segments: [RawSegment]
}

private struct RawGuards: Decodable {
    let roundStartDelayMs: Int
    let roundEndGuardMs: Int
    let warningGuardMs: Int
    let minGapMs: Int
    let maxConsecutiveNonCombo: Int
    let followsBoost: Double?
    let answerAfterNonCombo: Bool?
    let noRepeatWithinKind: [String: Int]
}

private struct RawSegment: Decodable {
    let id: String
    let share: Double
    let cadenceMs: [Int]
    let mix: [String: Double]
    let pools: [String: [RawPoolEntry]]
    let pinned: [RawPinned]?
}

private struct RawPoolEntry: Decodable {
    let id: String
    let weight: Double

    enum CodingKeys: String, CodingKey {
        case id
        case weight = "w"
    }
}

private struct RawPinned: Decodable {
    let id: String
    let atFromRoundEndMs: Int
}

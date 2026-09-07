import Foundation

/// The five kinds of call a coach makes. Ordering is the catalog's, not alphabetical.
public enum CoachKind: String, Codable, CaseIterable, Sendable {
    case combo, defence, movement, technique, effort
}

/// Whether a phrase needs one recording or one per naming convention.
///
/// A phrase forks only when it names punches by number — "One, two" and "Jab, cross" are the same
/// call spoken two ways. Everything else ("Circle left") is recorded once.
public enum ClipKind: String, Codable, Sendable {
    case forked, shared
}

/// How punches are named to the athlete. Lives in `SettingsStore` from change 2.
public enum NamingConvention: String, Codable, CaseIterable, Sendable {
    case numbers, names
}

/// What the coach says.
public enum CoachText: Sendable, Equatable {
    case shared(String)
    case forked(numbers: String, names: String)

    public func spoken(_ convention: NamingConvention) -> String {
        switch self {
        case .shared(let line):
            return line
        case .forked(let numbers, let names):
            return convention == .numbers ? numbers : names
        }
    }
}

/// What the running screen shows. Independent of `CoachText`: the ticker is terser than the speech
/// ("Last ten!" against "Last ten — everything you've got") and carries the modifier separately so
/// the view can set it apart.
public enum CoachTicker: Sendable, Equatable {
    case line(String)
    case punches(numbers: String, names: String, modifier: String?)

    public func primary(_ convention: NamingConvention) -> String {
        switch self {
        case .line(let line):
            return line
        case .punches(let numbers, let names, _):
            return convention == .numbers ? numbers : names
        }
    }

    public var modifier: String? {
        if case .punches(_, _, let modifier) = self { return modifier }
        return nil
    }
}

/// One call the coach can make.
///
/// Author notes in the JSON (`note`, `voice`, `intent`, `why`) are deliberately not decoded. They
/// describe what a segment is *for*, so a later script is written to the same shape — they are
/// never spoken. Leaving them out of the domain types makes speaking one structurally impossible
/// rather than merely discouraged.
public struct CoachPhrase: Sendable, Equatable, Identifiable {
    public let id: String
    public let kind: CoachKind
    public let clip: ClipKind
    public let tags: [String]
    /// Measured duration of the trimmed clip. The end-of-round guard depends on this being true,
    /// so it is rewritten from `afinfo` by `scripts/gen-coach-clips.py` after every recording.
    public let estMs: Int
    public let text: CoachText
    public let ticker: CoachTicker
    /// Tags this cue answers. A technique cue with `follows: ["jab"]` is boosted after a jab.
    public let follows: [String]
    /// Distance-from-round-end window this cue is eligible in, when it is only honest near the end.
    public let windowFromRoundEndMs: ClosedRange<Int>?

    /// The clip for this phrase under `convention`. Shared phrases ignore the convention.
    public func clipURL(for convention: NamingConvention, in bundle: Bundle) -> URL? {
        let directory = clip == .shared ? "shared" : convention.rawValue
        return bundle.url(forResource: id, withExtension: "m4a", subdirectory: "clips/\(directory)")
    }
}

import Foundation

public enum CoachCatalogError: Error, CustomStringConvertible, Equatable {
    case resourceMissing(String)
    case unknownKind(phrase: String, kind: String)
    case malformedPhrase(id: String, reason: String)

    public var description: String {
        switch self {
        case .resourceMissing(let name):
            return "coaching resource '\(name)' is not in the module bundle"
        case .unknownKind(let phrase, let kind):
            return "phrase '\(phrase)' has unknown kind '\(kind)'"
        case .malformedPhrase(let id, let reason):
            return "phrase '\(id)': \(reason)"
        }
    }
}

/// Every call the coach can make, keyed by phrase id.
///
/// Phrase ids are the single source of truth. Nothing in Swift inlines call text — a script names
/// ids, and the text comes from here.
public struct CoachCatalog: Sendable {
    public let version: Int
    public let level: String
    /// Authored order, preserved so previews and tests read in the same order as the JSON.
    public let order: [String]
    private let byID: [String: CoachPhrase]

    public var phrases: [String: CoachPhrase] { byID }

    public subscript(id: String) -> CoachPhrase? { byID[id] }

    public func phrases(ofKind kind: CoachKind) -> [CoachPhrase] {
        order.compactMap { byID[$0] }.filter { $0.kind == kind }
    }

    public init(data: Data) throws {
        let raw = try JSONDecoder().decode(RawCatalog.self, from: data)
        var built: [String: CoachPhrase] = [:]
        var ids: [String] = []
        for phrase in raw.phrases {
            guard let kind = CoachKind(rawValue: phrase.kind) else {
                throw CoachCatalogError.unknownKind(phrase: phrase.id, kind: phrase.kind)
            }
            guard let clip = ClipKind(rawValue: phrase.clip) else {
                throw CoachCatalogError.malformedPhrase(id: phrase.id, reason: "unknown clip '\(phrase.clip)'")
            }
            var window: ClosedRange<Int>?
            if let bounds = phrase.windowFromRoundEndMs {
                guard bounds.count == 2, bounds[0] <= bounds[1] else {
                    throw CoachCatalogError.malformedPhrase(
                        id: phrase.id, reason: "windowFromRoundEndMs must be [lo, hi] with lo <= hi")
                }
                window = bounds[0]...bounds[1]
            }
            built[phrase.id] = CoachPhrase(
                id: phrase.id, kind: kind, clip: clip, tags: phrase.tags, estMs: phrase.estMs,
                text: try phrase.text.resolved(id: phrase.id),
                ticker: try phrase.ticker.resolved(id: phrase.id),
                follows: phrase.follows ?? [], windowFromRoundEndMs: window)
            ids.append(phrase.id)
        }
        self.version = raw.version
        self.level = raw.level
        self.order = ids
        self.byID = built
    }

    /// Loads the catalog shipped inside this module.
    public static func bundled(_ bundle: Bundle = CoachingBundle.resources) throws -> CoachCatalog {
        guard let url = bundle.url(forResource: "phrases", withExtension: "json") else {
            throw CoachCatalogError.resourceMissing("phrases.json")
        }
        return try CoachCatalog(data: Data(contentsOf: url))
    }
}

// MARK: - Wire format
//
// Kept separate from the domain types so the JSON's polymorphism (text is a string or an object;
// ticker is a line or a pair) is resolved once, here, rather than leaking into every use site.

private struct RawCatalog: Decodable {
    let version: Int
    let level: String
    let phrases: [RawPhrase]
}

private struct RawPhrase: Decodable {
    let id: String
    let kind: String
    let clip: String
    let tags: [String]
    let estMs: Int
    let text: RawText
    let ticker: RawTicker
    let follows: [String]?
    let windowFromRoundEndMs: [Int]?
}

private enum RawText: Decodable {
    case line(String)
    case pair(numbers: String, names: String)

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let line = try? container.decode(String.self) {
            self = .line(line)
        } else {
            let pair = try container.decode([String: String].self)
            guard let numbers = pair["numbers"], let names = pair["names"] else {
                throw DecodingError.dataCorruptedError(
                    in: container, debugDescription: "forked text needs both numbers and names")
            }
            self = .pair(numbers: numbers, names: names)
        }
    }

    func resolved(id: String) throws -> CoachText {
        switch self {
        case .line(let line): return .shared(line)
        case .pair(let numbers, let names): return .forked(numbers: numbers, names: names)
        }
    }
}

private struct RawTicker: Decodable {
    let line: String?
    let numbers: String?
    let names: String?
    let modifier: String?

    func resolved(id: String) throws -> CoachTicker {
        if let line { return .line(line) }
        guard let numbers, let names else {
            throw CoachCatalogError.malformedPhrase(
                id: id, reason: "ticker needs either 'line' or both 'numbers' and 'names'")
        }
        return .punches(numbers: numbers, names: names, modifier: modifier)
    }
}

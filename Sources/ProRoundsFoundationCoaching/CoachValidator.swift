import Foundation

/// One integrity failure in the authored content.
public struct CoachIssue: Sendable, Equatable, CustomStringConvertible {
    public let location: String
    public let description: String

    init(_ location: String, _ message: String) {
        self.location = location
        self.description = location.isEmpty ? message : "\(location): \(message)"
    }
}

public struct CoachValidationReport: Sendable {
    public let errors: [CoachIssue]
    public let warnings: [CoachIssue]
    public var isValid: Bool { errors.isEmpty }
}

/// Mirrors `scripts/coach-script.py validate`, which is normative.
///
/// These run at load so an authoring mistake cannot reach the scheduler. Decoding already rejects
/// an unknown kind, a forked phrase missing a convention, and a shared phrase missing its ticker
/// line — those are structural and cannot survive `CoachCatalog.init`, so they are not re-checked
/// here.
///
/// One reference rule is **not** implemented yet: "a whole workout must be schedulable at the
/// shortest supported round", which calls `schedule()`. It lands with the scheduler.
public enum CoachValidator {
    private static let epsilon = 1e-9

    public static func validate(catalog: CoachCatalog) -> [CoachIssue] {
        var issues: [CoachIssue] = []
        let all = catalog.order.compactMap { catalog[$0] }

        for phrase in all where phrase.kind == .combo && !phrase.follows.isEmpty {
            issues.append(CoachIssue(phrase.id, "combos cannot declare follows"))
        }

        let produced = Set(all.flatMap(\.tags))
        let wanted = Set(all.flatMap(\.follows))
        for tag in wanted.subtracting(produced).sorted() {
            issues.append(CoachIssue("", "follows tag '\(tag)' is never produced by any phrase"))
        }
        return issues
    }

    /// Errors only, for callers that just want to know whether a script is usable.
    public static func validate(script: CoachScript, against catalog: CoachCatalog) -> [CoachIssue] {
        inspect(script: script, against: catalog).errors
    }

    /// Errors and warnings. A warning is content that will schedule but reads oddly — a phrase so
    /// long it forces a gap past its segment's cadence ceiling.
    static func inspect(
        script: CoachScript,
        against catalog: CoachCatalog
    ) -> (errors: [CoachIssue], warnings: [CoachIssue]) {
        var errors: [CoachIssue] = []
        var warnings: [CoachIssue] = []

        let shareTotal = script.segments.reduce(0) { $0 + $1.share }
        if abs(shareTotal - 1.0) > epsilon {
            errors.append(CoachIssue(script.id, "segment shares must sum to 1.0, got \(shareTotal)"))
        }

        for segment in script.segments {
            let place = "\(script.id)/\(segment.id)"
            errors += shapeIssues(segment, place: place, script: script)
            errors += pinnedIssues(segment, place: place, catalog: catalog)
            let pool = poolIssues(segment, place: place, script: script, catalog: catalog)
            errors += pool.errors
            warnings += pool.warnings
        }
        errors += unanswerableFollows(script, catalog: catalog)
        return (errors, warnings)
    }

    /// Shares, mix totals, empty pools behind a positive mix, and a reversed cadence range.
    private static func shapeIssues(_ segment: CoachSegment, place: String,
                                    script: CoachScript) -> [CoachIssue] {
        var issues: [CoachIssue] = []
        let mixTotal = segment.mix.values.reduce(0, +)
        if abs(mixTotal - 1.0) > epsilon {
            issues.append(CoachIssue(place, "mix must sum to 1.0, got \(mixTotal)"))
        }
        for (kind, share) in segment.mix where share > 0 && (segment.pools[kind] ?? []).isEmpty {
            issues.append(CoachIssue(place, "mix gives \(kind.rawValue) \(share) but its pool is empty"))
        }
        if let raw = script.rawCadence.first(where: { $0.0 == segment.id })?.1,
           raw.count == 2, raw[0] > raw[1] {
            issues.append(CoachIssue(place, "cadence min \(raw[0]) exceeds max \(raw[1])"))
        }
        return issues
    }

    /// A pinned cue must exist, and must not also sit in the draw pool — it would double up.
    private static func pinnedIssues(_ segment: CoachSegment, place: String,
                                     catalog: CoachCatalog) -> [CoachIssue] {
        segment.pinned.flatMap { pin -> [CoachIssue] in
            guard let phrase = catalog[pin.id] else {
                return [CoachIssue(place, "unknown pinned phrase '\(pin.id)'")]
            }
            guard (segment.pools[phrase.kind] ?? []).contains(where: { $0.id == pin.id }) else {
                return []
            }
            return [CoachIssue(place, "'\(pin.id)' is both pinned and in the draw pool")]
        }
    }

    /// Pool membership: window size against pool size, unknown ids, kind mismatches, weights, and
    /// the cadence-ceiling warning.
    private static func poolIssues(
        _ segment: CoachSegment, place: String, script: CoachScript, catalog: CoachCatalog
    ) -> (errors: [CoachIssue], warnings: [CoachIssue]) {
        var errors: [CoachIssue] = []
        var warnings: [CoachIssue] = []
        for (kind, entries) in segment.pools {
            let window = script.guards.noRepeatWithinKind[kind] ?? 0
            if !entries.isEmpty && window >= entries.count {
                errors.append(CoachIssue(place, "\(kind.rawValue) pool has \(entries.count) phrases "
                    + "but the no-repeat window is \(window) — every candidate can be blocked at once"))
            }
            for entry in entries {
                guard let phrase = catalog[entry.id] else {
                    errors.append(CoachIssue(place, "unknown phrase '\(entry.id)'"))
                    continue
                }
                if phrase.kind != kind {
                    errors.append(CoachIssue(place, "'\(entry.id)' is kind \(phrase.kind.rawValue), "
                        + "pooled under \(kind.rawValue)"))
                }
                if entry.weight <= 0 {
                    errors.append(CoachIssue(place, "'\(entry.id)' has non-positive weight"))
                }
                let floor = phrase.estMs + script.guards.minGapMs
                if floor > segment.cadenceMs.upperBound {
                    warnings.append(CoachIssue(place, "'\(entry.id)' (\(phrase.estMs)ms) forces a gap "
                        + "of \(floor)ms, past the \(segment.cadenceMs.upperBound)ms cadence ceiling"))
                }
            }
        }
        return (errors, warnings)
    }

    /// A cue whose `follows` tags nothing in *this* script produces can never play.
    private static func unanswerableFollows(_ script: CoachScript,
                                            catalog: CoachCatalog) -> [CoachIssue] {
        let used = Set(script.segments.flatMap { $0.pools.values.flatMap { $0.map(\.id) } })
        let producedHere = Set(used.compactMap { catalog[$0] }.flatMap(\.tags))
        return used.sorted().compactMap { id in
            guard let phrase = catalog[id], !phrase.follows.isEmpty,
                  producedHere.isDisjoint(with: phrase.follows) else { return nil }
            return CoachIssue(script.id, "'\(id)' follows \(phrase.follows) — no call in this "
                + "script produces those tags")
        }
    }

    /// Validates everything shipped in the module bundle.
    public static func validateBundled() throws -> CoachValidationReport {
        let catalog = try CoachCatalog.bundled()
        var errors = validate(catalog: catalog)
        var warnings: [CoachIssue] = []
        for name in CoachScript.bundledNames {
            let result = inspect(script: try CoachScript.bundled(name), against: catalog)
            errors += result.errors
            warnings += result.warnings
        }
        return CoachValidationReport(errors: errors, warnings: warnings)
    }
}

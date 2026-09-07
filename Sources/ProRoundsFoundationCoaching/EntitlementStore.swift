/// Whether the user is entitled to coaching.
///
/// Deliberately a **synchronous** read of local state returning a plain `Bool` — no `async`, no
/// publisher, no `Result`. That shape is the enforcement mechanism for the constraint that matters:
/// a paywall must never be able to stall, delay, or fail a round. There is no suspension point here
/// for a workout to wait on, so the guarantee holds by construction rather than by discipline.
///
/// The entitlement decides exactly one thing — whether the coaching cue stream is scheduled. It
/// does not affect phases, round counts, durations, audio cues, stored configurations, or
/// preferences, so nothing is lost when entitlement is later granted.
public protocol EntitlementStore: Sendable {
    var isCoachingEntitled: Bool { get }
}

/// The v1 implementation: everything unlocked, no paywall.
///
/// The seam exists so that landing a paywall later is a composition-root change rather than a
/// refactor across features (guide §5). When it does land, the leading candidate is a one-time
/// StoreKit 2 non-consumable — `Transaction.currentEntitlements` needs no backend and survives
/// reinstall, which respects local-first.
public struct UnlockedEntitlementStore: EntitlementStore {
    public init() {}
    public var isCoachingEntitled: Bool { true }
}

/// A store with a fixed answer, for exercising the locked path in tests.
public struct FixedEntitlementStore: EntitlementStore {
    public let isCoachingEntitled: Bool

    public init(isCoachingEntitled: Bool) {
        self.isCoachingEntitled = isCoachingEntitled
    }
}

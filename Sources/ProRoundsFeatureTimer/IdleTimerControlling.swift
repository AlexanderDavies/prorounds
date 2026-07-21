/// Keeps the screen awake while a workout runs (guide §3.5). The concrete (`UIApplication`) lives in
/// the app target; the workout view model depends only on this seam so it stays cross-platform and
/// testable.
@MainActor
public protocol IdleTimerControlling {
    func setDisabled(_ disabled: Bool)
}

/// Test double recording the current state.
@MainActor
public final class FakeIdleTimer: IdleTimerControlling {
    public private(set) var isDisabled = false
    public init() {}
    public func setDisabled(_ disabled: Bool) { isDisabled = disabled }
}

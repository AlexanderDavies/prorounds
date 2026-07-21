import UIKit
import ProRoundsFeatureTimer

/// Keeps the screen awake during a workout (guide §3.5). The `UIApplication`-backed concrete lives in
/// the always-iOS app target so `ProRoundsFeatureTimer` stays cross-platform.
@MainActor
final class AppIdleTimer: IdleTimerControlling {
    func setDisabled(_ disabled: Bool) {
        UIApplication.shared.isIdleTimerDisabled = disabled
    }
}

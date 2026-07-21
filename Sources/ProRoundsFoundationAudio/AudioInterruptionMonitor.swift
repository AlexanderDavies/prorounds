import Foundation
import AVFoundation

/// An audio-session interruption (e.g. a phone call) beginning or ending.
public enum InterruptionEvent: Sendable, Equatable {
    case began
    case ended
}

/// The seam the workout observes to pause/resume across interruptions (guide §7.5, §10.3). Backed by
/// `AVAudioSession` in production; a fake drives it in tests.
public protocol AudioInterruptionMonitoring: Sendable {
    var events: AsyncStream<InterruptionEvent> { get }
}

/// Production monitor observing `AVAudioSession.interruptionNotification` (iOS). On other hosts it
/// emits nothing, so the module still builds for the macOS test loop.
public final class SystemAudioInterruptionMonitor: AudioInterruptionMonitoring, @unchecked Sendable {
    public let events: AsyncStream<InterruptionEvent>
    private let continuation: AsyncStream<InterruptionEvent>.Continuation
    private var observer: (any NSObjectProtocol)?

    public init() {
        (events, continuation) = AsyncStream.makeStream()
        #if os(iOS)
        observer = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: nil
        ) { [continuation] note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
            switch type {
            case .began: continuation.yield(.began)
            case .ended: continuation.yield(.ended)
            @unknown default: break
            }
        }
        #endif
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        continuation.finish()
    }
}

/// Test double: the test emits interruption events by hand.
public final class FakeAudioInterruptionMonitor: AudioInterruptionMonitoring, @unchecked Sendable {
    public let events: AsyncStream<InterruptionEvent>
    private let continuation: AsyncStream<InterruptionEvent>.Continuation

    public init() {
        (events, continuation) = AsyncStream.makeStream()
    }

    public func send(_ event: InterruptionEvent) {
        continuation.yield(event)
    }
}

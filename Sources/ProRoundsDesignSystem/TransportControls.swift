import SwiftUI

/// The play/pause + reset cluster below the ring (`DESIGN.md` §6.4). Stateless: the caller supplies
/// the running/paused state, whether reset is available, and the tap callbacks.
public struct TransportControls: View {
    public let isRunning: Bool
    public let isResetEnabled: Bool
    public let onPlayPause: () -> Void
    public let onReset: () -> Void

    public init(
        isRunning: Bool,
        isResetEnabled: Bool,
        onPlayPause: @escaping () -> Void,
        onReset: @escaping () -> Void
    ) {
        self.isRunning = isRunning
        self.isResetEnabled = isResetEnabled
        self.onPlayPause = onPlayPause
        self.onReset = onReset
    }

    public var body: some View {
        HStack(spacing: Spacing.xl) {
            Button(action: onReset) {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.proIcon)
            .disabled(!isResetEnabled)
            .accessibilityLabel("Reset")

            Button(action: onPlayPause) {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
            }
            .buttonStyle(.proPrimaryCircle)
            .accessibilityLabel(isRunning ? "Pause workout" : "Start workout")
        }
    }
}

#Preview("TransportControls") {
    VStack(spacing: Spacing.xl) {
        TransportControls(isRunning: false, isResetEnabled: false, onPlayPause: {}, onReset: {})
        TransportControls(isRunning: true, isResetEnabled: true, onPlayPause: {}, onReset: {})
    }
    .padding()
}

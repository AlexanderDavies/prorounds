import SwiftUI
import ProRoundsDesignSystem

/// The pure content of the running screen (DESIGN §7.3): renders a `WorkoutDisplayModel` and forwards
/// intents. No view model, no lifecycle — so it snapshots deterministically in any phase.
struct WorkoutContentView: View {
    let display: WorkoutDisplayModel
    let title: String
    let finishedSummary: String
    let saveFailed: Bool
    let onPlayPause: () -> Void
    let onReset: () -> Void
    let onDone: () -> Void
    let onRetrySave: () -> Void
    let onEditCoaching: () -> Void

    var body: some View {
        ZStack {
            Rectangle().fill(ProRoundsColor.canvas).ignoresSafeArea()
            Rectangle().fill(phaseColor.opacity(0.08)).ignoresSafeArea() // subtle phase tint

            VStack(spacing: Spacing.xxl) {
                // Hidden under the minimal preference: during a coached round the call is what
                // matters, and the workout's name is not news by then.
                if !display.hidesSecondaryDetail {
                    Text(title)
                        .fontToken(.caption)
                        .foregroundStyle(ProRoundsColor.textSecondary)
                }

                if display.isFinished {
                    finishedView
                } else {
                    TimerRing(
                        progress: display.progress,
                        phaseColor: phaseColor,
                        badgeLabel: display.phaseLabel,
                        numeral: display.timeLabel,
                        totalRemaining: display.totalRemainingLabel
                    )

                    if let call = display.currentCall {
                        CoachTickerView(
                            primary: call.primary,
                            secondary: call.secondary,
                            modifier: call.modifier,
                            accessibleDescription: call.accessibleDescription
                        )
                        .transition(.opacity)
                        .accessibilityIdentifier("coachTicker")
                    }

                    // A pill above the transport, per the settled mockup — a shortcut into the
                    // same stored value the configuration editor writes, not a second setting.
                    if display.showsCoachingChip {
                        Button(action: onEditCoaching) {
                            Label(display.coachingChipLabel, systemImage: "figure.boxing")
                                .fontToken(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(ProRoundsColor.accent)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(ProRoundsColor.accent.opacity(0.12), in: Capsule())
                        .accessibilityIdentifier("coachChip")
                    }

                    TransportControls(
                        isRunning: display.isRunning,
                        isResetEnabled: true,
                        onPlayPause: onPlayPause,
                        onReset: onReset
                    )
                }
            }
            .padding(Spacing.lg)
        }
        .animation(.easeInOut(duration: 0.4), value: display.phaseStyle)
        .animation(.easeInOut(duration: 0.2), value: display.currentCall)
    }

    private var finishedView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(ProRoundsColor.phaseFinished)
            Text("Done")
                .fontToken(.display)
                .foregroundStyle(ProRoundsColor.textPrimary)
            Text(finishedSummary)
                .fontToken(.body)
                .foregroundStyle(ProRoundsColor.textSecondary)

            if saveFailed {
                VStack(spacing: Spacing.xs) {
                    Label("Couldn't save this session.", systemImage: "exclamationmark.triangle.fill")
                        .fontToken(.subhead)
                        .foregroundStyle(ProRoundsColor.danger)
                    Button("Retry", action: onRetrySave)
                        .buttonStyle(.proSecondary)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .padding(.top, Spacing.xs)
            }

            Button("Done", action: onDone)
                .buttonStyle(.proPrimary)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.top, Spacing.md)
        }
    }

    private var phaseColor: ThemeColor {
        switch display.phaseStyle {
        case .prepare: return ProRoundsColor.phasePrepare
        case .round: return ProRoundsColor.phaseRound
        case .rest: return ProRoundsColor.phaseRest
        case .finished: return ProRoundsColor.phaseFinished
        }
    }
}

/// The running workout hero screen: binds a `WorkoutViewModel` to `WorkoutContentView` and owns the
/// start/stop lifecycle.
public struct WorkoutView: View {
    @State private var model: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isEditingCoaching = false

    public init(model: WorkoutViewModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        WorkoutContentView(
            display: model.display,
            title: model.title,
            finishedSummary: model.finishedSummary,
            saveFailed: model.saveFailed,
            onPlayPause: { model.playPause() },
            onReset: { model.reset() },
            onDone: { dismiss() },
            onRetrySave: { model.retrySave() },
            onEditCoaching: { isEditingCoaching = true }
        )
        .onAppear { model.onAppear() }
        .onDisappear { model.onDisappear() }
        .sheet(isPresented: $isEditingCoaching) {
            CoachingSheetView(
                level: model.currentCoachingLevel,
                conventionOptions: model.conventionOptions,
                onSelectLevel: { level in
                    isEditingCoaching = false
                    Task { await model.setCoachingLevel(level) }
                },
                onSelectConvention: { model.selectConvention(id: $0) }
            )
        }
    }
}

import SwiftUI
import ProRoundsDataConfig
import ProRoundsDesignSystem
import ProRoundsFoundationUtilities

/// The create/edit editor, presented as a sheet. Dumb: it binds to the view model's draft and
/// forwards Save/Cancel/Delete; validation and persistence live in the view model.
public struct ConfigEditorView: View {
    @Bindable private var model: ConfigEditorViewModel
    private let onDone: () async -> Void
    @Environment(\.dismiss) private var dismiss

    public init(model: ConfigEditorViewModel, onDone: @escaping () async -> Void) {
        _model = Bindable(model)
        self.onDone = onDone
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Total", value: model.totalText)
                }

                Section("Name") {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "pencil")
                            .foregroundStyle(ProRoundsColor.textSecondary)
                            .accessibilityHidden(true)
                        // Blank shows the live auto-name as a placeholder; typing sets the custom name,
                        // clearing it reverts to the auto-name.
                        TextField(model.autoName, text: $model.draft.name)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Name")
                    .accessibilityValue(model.draft.name.isEmpty ? model.autoName : model.draft.name)
                }

                Section("Workout") {
                    Picker("Type", selection: $model.draft.workoutType) {
                        ForEach(WorkoutType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    Stepper("Rounds: \(model.draft.rounds)", value: $model.draft.rounds, in: 1...99)
                }

                Section("Timing") {
                    durationRow("Round time", seconds: $model.draft.roundSeconds, range: 5...3600, step: 5)
                    durationRow("Rest time", seconds: $model.draft.restSeconds, range: 0...1800, step: 5)
                    durationRow("Prep time", seconds: $model.draft.prepSeconds, range: 0...600, step: 5)
                    durationRow("Warning lead", seconds: $model.draft.warningLeadSeconds, range: 0...120, step: 1)
                }

                if !model.errors.isEmpty {
                    Section {
                        ForEach(model.errors, id: \.self) { error in
                            Label(message(for: error), systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(ProRoundsColor.danger)
                        }
                    }
                }

                if model.isEditing {
                    Section {
                        Button("Delete workout", role: .destructive) {
                            Task { await model.delete(); await onDone(); dismiss() }
                        }
                    }
                }
            }
            .navigationTitle(model.isEditing ? "Edit workout" : "New workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await model.save() { await onDone(); dismiss() }
                        }
                    }
                }
            }
        }
    }

    private func durationRow(_ label: String, seconds: Binding<Int>, range: ClosedRange<Int>, step: Int) -> some View {
        Stepper(value: seconds, in: range, step: step) {
            LabeledContent(label, value: DurationFormat.clock(.seconds(seconds.wrappedValue)))
        }
    }

    private func message(for error: ConfigurationValidationError) -> String {
        switch error {
        case .roundCountTooLow: return "At least one round is required."
        case .roundDurationNotPositive: return "Round time must be greater than zero."
        case .restDurationNegative: return "Rest time can't be negative."
        case .prepDurationNegative: return "Prep time can't be negative."
        case .warningLeadOutOfRange: return "Warning lead must be shorter than the round."
        case .coachingUnavailableForWorkoutType:
            return "Coaching isn't available for this workout type yet."
        }
    }
}

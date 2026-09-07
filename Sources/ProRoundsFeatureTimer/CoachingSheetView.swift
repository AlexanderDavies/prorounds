import SwiftUI
import ProRoundsDataConfig
import ProRoundsDesignSystem

/// The coaching options for this workout, reached from the chip on the idle screen.
///
/// Two settings stored in different places on purpose: the **level** belongs to this workout and
/// lives on its configuration; the **naming convention** belongs to the person and is stored once in
/// settings. Both appear here because this is the moment they matter — the convention is mirrored in
/// Settings, and it is one stored value either way.
struct CoachingSheetView: View {
    let level: CoachingLevel?
    let conventionOptions: [CoachingConventionOption]
    let onSelectLevel: (CoachingLevel?) -> Void
    let onSelectConvention: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Coach") {
                    row("Off", isSelected: level == nil) { onSelectLevel(nil) }
                    ForEach(CoachingLevel.allCases, id: \.self) { option in
                        row(option.displayName, isSelected: level == option) { onSelectLevel(option) }
                    }
                }

                Section {
                    ForEach(conventionOptions) { option in
                        row(option.label, isSelected: option.isSelected) {
                            onSelectConvention(option.id)
                        }
                    }
                } header: {
                    Text("How punches are called")
                } footer: {
                    Text("Also in Settings. Applies to every coached workout.")
                }
            }
            .navigationTitle("Coaching")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func row(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label).foregroundStyle(ProRoundsColor.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark").foregroundStyle(ProRoundsColor.accent)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

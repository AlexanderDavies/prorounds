import SwiftUI
import ProRoundsDataSettings
import ProRoundsFoundationCoaching
import ProRoundsDesignSystem
import ProRoundsFoundationAudio
import ProRoundsFoundationUtilities

/// The Settings tab (DESIGN §7.5): warning sound (select + preview), timer display, and appearance.
/// Dumb — it forwards intents to the view model, which persists and previews.
public struct SettingsView: View {
    @State private var model: SettingsViewModel

    public init(model: SettingsViewModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Warning sound") {
                    ForEach(WarningSound.allCases, id: \.self) { sound in
                        selectRow(warningLabel(sound), systemImage: warningIcon(sound),
                                  isSelected: model.warningSound == sound) {
                            model.selectWarningSound(sound)
                        }
                    }
                }

                Section("Timer display") {
                    selectRow("Count down", systemImage: "arrow.down",
                              isSelected: model.countDirection == .countDown) {
                        model.setCountDirection(.countDown)
                    }
                    selectRow("Count up", systemImage: "arrow.up",
                              isSelected: model.countDirection == .countUp) {
                        model.setCountDirection(.countUp)
                    }
                }

                // Each option carries an example of the coach's actual words: someone who does not
                // yet know the numbering cannot choose between "Numbers" and "Names" otherwise.
                Section("Coaching") {
                    ForEach(NamingConvention.allCases, id: \.self) { convention in
                        selectRow("\(convention.displayName) — \u{201C}\(convention.example)\u{201D}",
                                  systemImage: convention == .numbers ? "number" : "textformat",
                                  isSelected: model.namingConvention == convention) {
                            model.setNamingConvention(convention)
                        }
                    }
                    Toggle(isOn: Binding(
                        get: { model.minimalRunningScreen },
                        set: { model.setMinimalRunningScreen($0) }
                    )) {
                        Label("Minimal running screen", systemImage: "rectangle.compress.vertical")
                    }
                }

                Section("Appearance") {
                    ForEach(ColorSchemePreference.allCases, id: \.self) { preference in
                        selectRow(appearanceLabel(preference), systemImage: appearanceIcon(preference),
                                  isSelected: model.appearance == preference) {
                            model.setAppearance(preference)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(ProRoundsColor.canvas)
        }
    }

    private func selectRow(_ title: String, systemImage: String, isSelected: Bool,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: systemImage)
                    .frame(width: 24)
                    .foregroundStyle(ProRoundsColor.textSecondary)
                Text(title).foregroundStyle(ProRoundsColor.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundStyle(ProRoundsColor.accent)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func warningLabel(_ sound: WarningSound) -> String {
        switch sound {
        case .woodenClap: return "Wooden clap"
        case .electronicHorn: return "Electronic horn"
        case .buzzer: return "Buzzer"
        }
    }

    private func warningIcon(_ sound: WarningSound) -> String {
        switch sound {
        case .woodenClap: return "hands.clap.fill"
        case .electronicHorn: return "speaker.wave.3.fill"
        case .buzzer: return "alarm.fill"
        }
    }

    private func appearanceLabel(_ preference: ColorSchemePreference) -> String {
        switch preference {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }

    private func appearanceIcon(_ preference: ColorSchemePreference) -> String {
        switch preference {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "iphone"
        }
    }
}

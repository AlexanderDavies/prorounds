## 1. Settings store (ProRoundsDataSettings)

- [x] 1.1 Add `ProRoundsDataSettings` deps on FoundationAudio + FoundationUtilities in `Package.swift`; add the `ProRoundsDataSettingsTests` test target
- [x] 1.2 Write failing tests: fresh defaults (count down, system); UserDefaults round-trip via a unique suite; in-memory fake round-trip (spec: settings-store)
- [x] 1.3 Implement `ColorSchemePreference` (light/dark/system), the `SettingsStore` protocol, `UserDefaultsSettingsStore`, and `InMemorySettingsStore` — green

## 2. Settings view model (ProRoundsFeatureSettings)

- [x] 2.1 Add the `ProRoundsFeatureSettingsTests` test target (SnapshotTesting + `__Snapshots__` excluded) in `Package.swift`
- [x] 2.2 Write failing `SettingsViewModel` tests (over the in-memory store + a `SpyAudioCuePlayer`): selecting a warning sound persists it and plays a preview; setting count direction / appearance persists them (spec: settings-screen)
- [x] 2.3 Implement `@MainActor @Observable SettingsViewModel` (mirrors the store, write-through setters, preview on sound selection) — green

## 3. Settings screen

- [x] 3.1 Build `SettingsView` (dumb): grouped sections — warning sound (3 selectable rows w/ checkmark, tap = select + preview), timer display (count down/up), appearance (Light/Dark/System); compose design tokens (spec: settings-screen)
- [x] 3.2 Add a settings-screen snapshot test (light + dark)

## 4. Composition & app wiring

- [x] 4.1 `AppEnvironment` gains `settingsStore` (`UserDefaultsSettingsStore`); the app builds a shared `SettingsViewModel(store:player:)`
- [x] 4.2 Apply `.preferredColorScheme` at the app root from the shared view model; wire the Settings tab to `SettingsView`; `project.yml` gains `ProRoundsFeatureSettings` + `ProRoundsDataSettings`; regenerate
- [x] 4.3 `ViewModelFactory.workout(_:)` reads `settingsStore.countDirection` + `.warningSound` (were injected defaults)

## 5. Verification

- [x] 5.1 `./scripts/test.sh` + `./scripts/coverage.sh` green; `./scripts/lint.sh` strict clean; `./scripts/snapshot.sh` green
- [x] 5.2 Settings screen verified via snapshot (light + dark) — grouped sections, red-accent checkmarks. XCUITest taps the Settings tab, asserts the 'Warning sound' section, and taps the Light appearance control (no crash). The live theme-flip is standard SwiftUI (@Observable appearance → preferredColorScheme) — not screenshot-verified; the warning-sound preview audio is a manual-only check (SpyAudioCuePlayer proves it's triggered)
- [x] 5.3 Module graph compiles (DataSettings imports no Feature; FeatureSettings imports no sibling Feature); `openspec validate settings` clean; README updated (MVP feature-complete)

## Context

The warning sound, count direction, and appearance have been injected defaults since the workout and (implicitly) app-root shipped. This change adds the `SettingsStore` (guide §6.4) and the Settings tab (DESIGN §7.5), and wires them so user choices persist and take effect. It is the last MVP screen.

## Goals / Non-Goals

**Goals:**
- A `SettingsStore` (protocol + `UserDefaults` impl + in-memory fake) for warning sound, count direction, and appearance.
- The Settings tab: warning-sound selection + preview, count direction, appearance (light/dark/system).
- Appearance applied app-wide, reactively; the workout reads the stored count direction + warning sound.

**Non-Goals:**
- Phase-2 WHOOP row; any preference beyond the three in the prompt.

## Decisions

- **D1 — Store shape.** `SettingsStore` is a small synchronous `Sendable` protocol with get/set for `warningSound`, `countDirection`, and `ColorSchemePreference` (a new plain enum in DataSettings — no SwiftUI import; the app maps it to `ColorScheme?`). `UserDefaultsSettingsStore` reads/writes `UserDefaults` per property with default fallbacks (count down, system); `InMemorySettingsStore` is the test fake. `ProRoundsDataSettings` depends on FoundationAudio (`WarningSound`) and FoundationUtilities (`CountDirection`) — both Foundation-layer.
- **D2 — A shared `@Observable SettingsViewModel`.** It mirrors the store's values as observable state (initialised from the store), and its setters write through to the store. Warning-sound selection also **previews** the sound via an injected `AudioCuePlayer` (`play(.roundEndWarning(sound))`). It is the single reactive source the app root observes.
- **D3 — Appearance at the app root.** `ProRoundsApp` builds and holds the shared `SettingsViewModel`; the root content applies `.preferredColorScheme(pref.colorScheme)` where `light → .light`, `dark → .dark`, `system → nil`. Because the view model is `@Observable`, changing appearance in Settings re-applies immediately.
- **D4 — Features read current settings.** `ViewModelFactory.workout(_:)` reads `environment.settingsStore.countDirection` and `.warningSound` when it builds a workout, so a change applies to the next workout (the engine + view model are constructed per run). No live re-wiring of a running workout is needed.
- **D5 — Composition.** `AppEnvironment` gains `settingsStore` (`UserDefaultsSettingsStore`) and already exposes the audio player. The app builds one `SettingsViewModel(store:, player:)`, injects it into `RootView` (for `preferredColorScheme` and the Settings tab) — the Settings tab hosts `SettingsView(model:)`.

## Risks / Trade-offs

- **`UserDefaults` test isolation** → store tests use `UserDefaults(suiteName:)` with a unique name and clean it up; view-model tests use the in-memory fake, so they never touch disk.
- **`preferredColorScheme` reactivity** → the shared `@Observable` view model drives it; a quick simulator check confirms Dark/Light/System switch live.
- **Preview plays through the shared session** → the same `.playback`/`.duckOthers` `AVAudioCuePlayer`; previewing from Settings is fine and matches how a cue sounds.

## Open Questions

- Whether to show a disabled "WHOOP — Coming soon" row (DESIGN §7.5 mentions it as a Phase-2 placeholder) — left out to keep MVP settings to the three real controls; trivial to add later.

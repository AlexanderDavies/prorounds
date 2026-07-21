## Why

Three settings have been running on injected defaults since the features that use them shipped — the warning sound, the count-up/down timer display, and the light/dark/system appearance. This change gives the user control of them via the Settings tab and persists the choices, closing out the MVP: every screen from the app prompt now exists.

## What Changes

- Add the **`SettingsStore`** in `ProRoundsDataSettings` (guide §6.4): a small, synchronous `Sendable` protocol for the non-sensitive preferences — `WarningSound`, `CountDirection`, and a new `ColorSchemePreference` (light / dark / system) — with a `UserDefaults`-backed implementation and an in-memory fake for tests.
- Build the **Settings tab** in `ProRoundsFeatureSettings` (DESIGN §7.5): a `@MainActor @Observable SettingsViewModel` over the store and a dumb `SettingsView` with grouped sections — **warning sound** (three selectable rows, tapping one selects it **and previews the sound**), **timer display** (count down / count up), and **appearance** (Light / Dark / **System** default).
- **Apply the appearance app-wide**: the app root sets `preferredColorScheme` from the preference and re-applies it reactively when the user changes it.
- **Wire the settings into the features**: the workout view model's count direction and the engine's warning sound now come from the store (were injected defaults) — read when each workout is built, so a change applies to the next workout. The Settings tab replaces its placeholder.

Non-goals (deferred): the Phase-2 **WHOOP** connection (a disabled "Coming soon" row is out of scope here), and any settings beyond the three in the prompt.

## Capabilities

### New Capabilities
- `settings-store`: The `SettingsStore` protocol, its `UserDefaults`-backed implementation, and the persisted preferences (`WarningSound`, `CountDirection`, `ColorSchemePreference`).
- `settings-screen`: The Settings tab — warning-sound selection with preview, timer-display direction, and the light/dark/system appearance control, applied app-wide.

### Modified Capabilities
- `app-shell`: The Settings tab shows the settings screen (was a placeholder); the app applies the appearance preference.

## Impact

- **Fleshes out** `ProRoundsDataSettings` (store + fake) and `ProRoundsFeatureSettings` (view model + view); extends the composition root (build the store; a shared settings view model drives `preferredColorScheme`; the factory reads current settings when building workout view models).
- **`project.yml`**: the app target gains `ProRoundsFeatureSettings` + `ProRoundsDataSettings`; regenerate.
- **`ProRoundsDataSettings`** references `WarningSound` (FoundationAudio) and `CountDirection` (FoundationUtilities) — both Foundation-layer, so the layering holds.
- Store + view model unit-tested against the in-memory fake (fast macOS loop); the settings screen snapshot-tested; the appearance application verified in the simulator.
- No new third-party dependencies; local-first preserved (`UserDefaults`, on-device).

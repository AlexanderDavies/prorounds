## Why

Everything exists to run a workout except the workout itself. This change delivers ProRounds' hero screen — the running timer — by wiring the proven `RoundTimerEngine` into a view with real audio cues, and it resolves the app prompt's open **background-audio** question (confirmed: keep firing cues with the screen locked). After this, the core product loop works end-to-end: pick a config → run prep/rounds/rests with bell + warning cues → finish.

## What Changes

- Add the **concrete `AVAudioCuePlayer`** in `ProRoundsFoundationAudio`: preloads bundled sound assets and plays cues with low latency, mapping each `AudioCue` to a sound (bell for round start/end/rest, the selected `WarningSound` for the warning, a distinct complete cue). Configures `AVAudioSession` for `.playback` with **`.duckOthers`** (music dips for a cue), declares the **`audio` background mode** so cues fire with the screen locked / app backgrounded, and handles **route changes** and **interruptions**. iOS-only session APIs are `#if os(iOS)`-guarded so the module still builds on the macOS test host.
- **Synthesized placeholder sound assets** (bell + wooden clap + electronic horn + buzzer + complete), bundled as resources — clearly placeholders, easy to swap for final audio later (DESIGN §10/§11 flags real assets as open).
- Add the **workout hero screen** in `ProRoundsFeatureTimer` (DESIGN §7.3): a `@MainActor @Observable WorkoutViewModel` that drives the engine and maps its `WorkoutSnapshot`s to a `WorkoutDisplayModel` (phase label, formatted numeral resolving count-up/down, total-remaining, ring progress, phase color, paused/finished), a dumb `WorkoutView` composing `TimerRing`/`PhaseBadge`/`TransportControls` with a phase-tinted background and a finished summary, transport intents (play/pause/reset), and **keep-screen-awake** while running (an injected seam).
- Add **interruption resilience**: an interruption seam whose events pause the engine on a call/route loss and resume cleanly — the workout is never silently corrupted (invariant §0.6.4).
- **Launch a workout from the list**: tapping a configuration card now starts its workout (DESIGN §7.1); create stays on `+` and edit moves to a swipe action. Add the `.running` route; the composition root builds the engine (real clock + audio player) and the workout view model via the factory.
- Add a minimal **XCUITest** target for the UI flow (list → start → pause → reset → back), establishing UI-flow testing (guide §14.2).

Non-goals (deferred): **saving the completed session** (needs `SessionRepository` → change #7; the finished screen shows a summary but persists nothing yet), the **Performance** chart (#8), and **settings** wiring — count direction and the selected warning sound use injected defaults until change #9.

## Capabilities

### New Capabilities
- `audio-playback`: The concrete `AVAudioCuePlayer` — bundled assets, low-latency playback, the `.playback`/`.duckOthers` session, background-audio, and the cue→sound mapping.
- `workout-runtime`: The running workout screen — view model driving the engine, display mapping (count direction), transport, phase-tinted UI, keep-awake, the finished summary, and launching from a config.
- `interruption-resilience`: Pausing and resuming the workout cleanly across audio-session interruptions and route changes.

### Modified Capabilities
- `config-list`: The card's primary tap now starts the workout (was: opens the editor); create/edit move to explicit `+`/swipe affordances.

## Impact

- **Fleshes out** `ProRoundsFoundationAudio` (concrete player, session, assets, seams), extends `ProRoundsFeatureTimer` (workout screen + view model + display mapping + keep-awake seam), and `ProRoundsFoundationUtilities` (a shared `CountDirection`).
- **App target + `project.yml`**: adds `ProRoundsFeatureTimer` + `ProRoundsFoundationAudio` product deps, the `UIBackgroundModes: [audio]` Info.plist key, the concrete keep-awake/idle-timer (`UIApplication`), and the `.running` navigation. A new XCUITest target + scheme test action.
- **Resolves the background-audio product decision** (keep firing cues when locked; duck other audio) — the one open question from the prompt.
- View models/mappers unit-tested against `FakeTimeSource` + `SpyAudioCuePlayer` + fakes (fast macOS loop); the hero screen snapshot-tested (phases, paused, finished) and the flow driven by XCUITest in the simulator. The concrete audio player is a platform-edge adapter (excluded from the coverage gate; its cue→sound mapping is extracted and unit-tested).
- No new third-party dependencies; local-first preserved (bundled audio, no network).

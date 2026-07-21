## Context

The `RoundTimerEngine` (deterministic, deadline-based) and the `AudioCuePlayer` seam exist from change #2; the design-system components and the config feature exist. This change wires them into the running screen with a real audio player and interruption resilience. Confirmed product decisions: **background audio on** (cues fire when locked), **duck** other audio, **synthesized placeholder** sounds.

## Goals / Non-Goals

**Goals:**
- The workout hero screen driven by the engine, with real bell/warning cues.
- Background-audio cues, ducking, and clean interruption/route handling.
- Keep-screen-awake; count-up/down display; finished summary; launch from a config.
- View models/mappers on the fast macOS loop; the screen + flow verified on the simulator.

**Non-Goals:**
- Saving the completed session (→ #7 — finished screen shows a summary, persists nothing).
- Performance chart (#8); settings wiring (count direction + warning sound use injected defaults until #9).

## Decisions

- **D1 — Cross-platform modules, iOS-guarded edges.** `ProRoundsFoundationAudio` and `ProRoundsFeatureTimer` stay macOS-buildable so the engine and view-model tests keep running on the fast host loop. iOS-only APIs — `AVAudioSession`, `UIApplication.isIdleTimerDisabled`, background mode, interruption notifications — are `#if os(iOS)` / `#if canImport(UIKit)`-guarded; on macOS they compile to no-ops.
- **D2 — Cue→sound mapping is a pure function.** The `AVAudioCuePlayer` (a platform-edge adapter, excluded from the coverage gate per §14.4) is thin: it wraps `AVAudioPlayer` + the session and delegates *which sound* to a pure `cueSound(for:) -> SoundAsset` function that is unit-tested independently of hardware.
- **D3 — Synthesized placeholder assets.** A committed script generates five short WAVs — `bell`, `wooden_clap`, `electronic_horn`, `buzzer`, `complete` — bundled as `ProRoundsFoundationAudio` resources (`.process`) and loaded via `Bundle.module`. Clearly placeholder; DESIGN §11 flags final assets as open.
- **D4 — Interruption seam.** `AudioInterruptionMonitoring` exposes an `AsyncStream<InterruptionEvent>` (`.began`/`.ended`); the concrete observes `AVAudioSession.interruptionNotification` (iOS-guarded). The `WorkoutViewModel` subscribes and calls `engine.togglePause()` to pause on `.began` and resume on `.ended` — the deadline engine recomputes remaining on resume (§7.5). A fake drives it deterministically in tests.
- **D5 — Keep-awake seam.** `IdleTimerControlling` protocol in `ProRoundsFeatureTimer`; the concrete `AppIdleTimer` (`UIApplication.isIdleTimerDisabled`) lives in the always-iOS app target. The view model disables idle on start and restores it on finish/disappear. A fake asserts the toggling in tests.
- **D6 — Engine snapshot delivery.** The engine gains a `snapshots` `AsyncStream` its tick loop yields to (plus the initial snapshot). `WorkoutViewModel.onAppear` consumes it — `for await snap in engine.snapshots { display = WorkoutDisplayModel(snap, direction:) }` — owning that task and cancelling it on `deinit`. This is the observation mechanism behind the workout-runtime "reflects snapshots" requirement.
- **D7 — Navigation.** `TimerRoute` gains `.running(Configuration.ID)`. The list hosts a `NavigationStack(path:)`; a card tap pushes `.running` (→ `WorkoutView`); the editor stays a `.sheet` reached from `+`/swipe-Edit. Finishing a workout pops back to the list.
- **D8 — Count direction & warning sound defaults.** `CountDirection` (a shared enum in `ProRoundsFoundationUtilities`, like `WorkoutType`) defaults to `.countDown`; the engine's `WarningSound` defaults (e.g. `.woodenClap`). Both are injected at the composition root and rewired to settings in #9.
- **D9 — XCUITest via a launch-seed.** A new UI-test target (in `project.yml`) drives list → start → pause → reset. Launched with `-uiTestSeed`, the app uses an in-memory store pre-seeded with one demo config (hermetic — no disk pollution), so the test taps a known card. Assertions are on presence/state (accessibility identifiers), never timer math (§14.6).

## Risks / Trade-offs

- **Background-audio correctness can't be fully automated** (locked-screen cue firing) → Mitigation: unit-test the mapping + session-option selection; verify audibility/ducking/lock behaviour manually in the simulator; document the entitlement + session lifecycle.
- **Placeholder audio quality** → Acceptable and explicitly labelled; swap-in path documented.
- **XCUITest + a live real-clock timer** → assert on state/labels and short waits, not on exact times; the engine's timing is already exhaustively unit-tested.
- **`AsyncStream` snapshot consumption / cancellation** → the view model owns and cancels the task; a test drives a `FakeTimeSource` engine and asserts the display updates.

## Open Questions

- **Route-change policy** (headphones unplugged): continue vs pause. Default chosen: **continue** (a workout timer shouldn't halt because audio route changed); revisit if it feels wrong.
- Final sound assets and loudness (DESIGN §11) — placeholders now.

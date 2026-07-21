## Why

The round-timer engine is ProRounds' defining component and its hardest correctness problem — "timer correctness is the product" (invariant §0.6.2). Building it now, in isolation and fully test-first against fakes, lets us *prove* the workout sequence, deadline accuracy, pause/resume, and exact cue order deterministically before any UI, audio hardware, or persistence exists to obscure a bug. Every later change (workout screen, audio, sessions) plugs into a proven engine.

## What Changes

- Introduce the **workout domain value types** the engine operates on: `WorkoutType` (the five types in spec order) and a pure `Configuration` value type (rounds, round/rest/prep durations, warning lead, name). Persistence, validation, and the SwiftData entity are **not** here — they arrive in change #4; this is the in-memory domain only.
- Introduce the **`RoundTimerEngine`**: a deterministic, `@MainActor` state machine over the injected `TimeSource` that sequences `prep → (round → rest) × N` **with no rest after the final round**, exposes `start()` / `togglePause()` / `reset()`, and publishes `Sendable` `WorkoutSnapshot`s (phase, remaining, elapsed-in-phase, elapsed-total, total, paused).
- Time is **monotonic-deadline-based, never a tick accumulator** (§7.2): each phase has an absolute deadline; `remaining = deadline − now`; pause captures remaining, resume rebuilds the deadline as `now + remaining`. Verified across slow ticks, pause/resume, reset, and phase transitions.
- Introduce the **`AudioCuePlayer` seam** and its cue vocabulary (`AudioCue`, `WarningSound`) so the engine emits cues — round start, round-end warning at `deadline − warningLead` (only when `warningLead > 0`), round end / rest start, workout complete — **from the engine, not the view**. The concrete `AVFoundation` player is deferred to change #6; here the engine drives the protocol and tests assert cue order against a spy.
- **Modify the `TimeSource` seam** to add a `ticks(interval:)` stream (~10–20 Hz) the engine drives its display updates from, per guide §7.3, with the fake emitting ticks by hand. The existing `now` / `sleep(until:)` behaviour is unchanged.

Non-goals (deferred): any SwiftUI/view/view-model or count-up-vs-down display mapping (change #6), the concrete audio player and `AVAudioSession`/background handling (change #6), SwiftData persistence and configuration validation rules (change #4), and biometrics (Phase 2).

## Capabilities

### New Capabilities
- `workout-configuration`: The workout domain value types — `WorkoutType` (five types, spec order) and the pure `Configuration` the engine consumes (in-memory only; persistence/validation deferred to change #4).
- `round-timer-engine`: The deterministic phase state machine — the exact `prep → (round → rest) × N` sequence, monotonic-deadline timing, start/pause/resume/reset, and the observable snapshot stream.
- `audio-cues`: The `AudioCuePlayer` protocol plus the `AudioCue` and `WarningSound` types — the cue vocabulary the engine emits at transition instants and the warning lead time (concrete player deferred).

### Modified Capabilities
- `time-source`: Add a `ticks(interval:)` display-update stream to the `TimeSource` seam (real repeating source + hand-driven fake ticks), so the engine can update the ring smoothly. Existing monotonic `now` / `sleep(until:)` behaviour is unchanged.

## Impact

- **Fleshes out placeholder modules:** `ProRoundsDataConfig` (domain `Configuration` + `WorkoutType`, no SwiftData yet), `ProRoundsFoundationAudio` (`AudioCuePlayer` protocol, `AudioCue`, `WarningSound`, plus a `SpyAudioCuePlayer` test double), `ProRoundsFeatureTimer` (the `RoundTimerEngine`).
- **Extends** `ProRoundsFoundationTiming` (`ticks(interval:)` on `TimeSource`, `RealTimeSource`, `FakeTimeSource`) — additive; existing tests stay green.
- **New test targets** for the engine and the audio/domain types; the engine is exhaustively tested against `FakeTimeSource` + `SpyAudioCuePlayer` with the exact cue order asserted, and is **never excluded from coverage**.
- **No UI, no persistence, no real audio, no network** — invariants preserved. Pure, hermetic, microsecond-fast tests.

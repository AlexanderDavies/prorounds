## 1. Workout domain value types

- [x] 1.1 Write failing tests for `WorkoutType`: five cases in spec order (Shadow Boxing, Skipping, Heavy Bag, Speed Ball, Sparring) and display names (spec: workout-configuration)
- [x] 1.2 Add `WorkoutType` to `ProRoundsFoundationUtilities` (pure, `CaseIterable`/`Sendable`, `displayName`) — green
- [x] 1.3 Write failing tests for `Configuration` in `ProRoundsDataConfig`: total duration via the single-source calculator (47:10 case), effective name = custom when present else auto (spec: workout-configuration)
- [x] 1.4 Add the immutable `Configuration` value type (`Sendable`/`Equatable`) with `totalDuration`/`effectiveName` delegating to `WorkoutMath` — green

## 2. Audio-cue seam

- [x] 2.1 Write failing tests for `WarningSound` (three cases: wooden clap, electronic horn, buzzer; `CaseIterable`/`Codable`) and `AudioCue` equality (spec: audio-cues)
- [x] 2.2 Add `WarningSound`, `AudioCue`, and the `AudioCuePlayer` protocol (`prepare()`/`play(_:)`, `Sendable`) to `ProRoundsFoundationAudio` — green
- [x] 2.3 Add `SpyAudioCuePlayer` (records `played: [AudioCue]` in order) and a test proving it records play order (spec: audio-cues)

## 3. TimeSource tick stream (modifies time-source)

- [x] 3.1 Write failing tests: `FakeTimeSource` yields a tick on demand and nothing on its own; existing `now`/`sleep` tests still pass (spec: time-source)
- [x] 3.2 Add `ticks(interval:)` to the `TimeSource` protocol and `FakeTimeSource` (hand-driven emission) — green
- [x] 3.3 Implement `ticks(interval:)` on `RealTimeSource` (repeating `ContinuousClock` loop yielding `now`); test approximate spacing/monotonicity

## 4. RoundTimerEngine — the reducer core (pure, TDD)

- [x] 4.1 Define `WorkoutPhase` and `WorkoutSnapshot` (`Equatable`/`Sendable`) in `ProRoundsFeatureTimer`
- [x] 4.2 Write failing tests for the exact sequence: 3-round workout → preparing, round 1, rest 1, round 2, rest 2, round 3, finished; no rest after the final round; 1-based indices bounded by N (spec: round-timer-engine)
- [x] 4.3 Write failing tests: zero prep starts at round 1 (no zero-length preparing) (spec: round-timer-engine)
- [x] 4.4 Implement the synchronous `process(at:)` reducer + engine state to pass 4.2–4.3 — green
- [x] 4.5 Write failing tests for monotonic-deadline timing: coarse/irregular ticks end a phase exactly at its deadline; a long gap crossing several deadlines transitions through exactly the crossed phases; `remaining == deadline − now`, never negative (spec: round-timer-engine)
- [x] 4.6 Extend the reducer to loop transitions when several deadlines are crossed in one step — green
- [x] 4.7 Write failing tests for snapshots: `remaining + elapsedInPhase == phase duration`; `elapsedTotal` consistency (spec: round-timer-engine)

## 5. Transport, cues & terminal state

- [x] 5.1 Write failing tests for pause/resume: no time accrues while paused; resume rebuilds `deadline = now + remaining`; `isPaused` reflected in snapshot; no cue fires from time passing while paused (spec: round-timer-engine)
- [x] 5.2 Write failing tests for `reset()`: returns to pre-start state; reset-then-restart runs the full sequence again (spec: round-timer-engine)
- [x] 5.3 Write failing tests for the warning cue: fires once per round at `deadline − lead` (50s into a 60s round with 10s lead); suppressed entirely when lead is 0; clamped to round start when lead ≥ round (spec: round-timer-engine)
- [x] 5.4 Write failing tests for cue order: 2-round workout emits round start → warning → round end → rest start → round start → warning → round end → workout complete (spec: round-timer-engine)
- [x] 5.5 Write failing tests for terminal `finished`: complete fires exactly once; advancing further yields no transitions/cues (spec: round-timer-engine)
- [x] 5.6 Implement `start`/`togglePause`/`reset`, cue emission, and the terminal state to pass 5.1–5.5 — green

## 6. Async tick driver & wiring

- [x] 6.1 Add the `@MainActor` engine's async tick loop (`for await instant in timeSource.ticks(...) { apply(process(at: instant)) }`) exposing an Observable `snapshot`
- [x] 6.2 Write an integration test driving the engine through a short workout via `FakeTimeSource` ticks + `SpyAudioCuePlayer`, asserting final snapshot and full cue order — green

## 7. Verification

- [x] 7.1 Full suite green via `./scripts/test.sh`; coverage gate passes with the engine included (never excluded)
- [x] 7.2 SwiftLint strict clean (`./scripts/lint.sh`); the module graph still compiles (no layering violation)
- [x] 7.3 `openspec validate round-timer-engine` clean

## Context

The `RoundTimerEngine` is the core of ProRounds and the subject of the strictest correctness invariants (§0.6.2–§0.6.3) and the most tests (guide §7, §14.1). Change #1 delivered the `TimeSource` seam (`now` + `sleep(until:)` + a deterministic `FakeTimeSource`) and the single-source duration/auto-name calculators. This change builds the engine and the domain and cue seams it needs, entirely test-first against fakes — no UI, no real audio, no persistence. Guide §7.3 specifies the engine drives display updates from a `ticks(interval:)` stream, which change #1's seam does not yet have; reconciling that is part of this change.

## Goals / Non-Goals

**Goals:**
- A deterministic engine that honours `prep → (round → rest) × N` exactly (no rest after round N), timed by monotonic deadlines, with correct pause/resume/reset.
- Cues emitted from the engine (round start, warning at lead, round end, rest start, complete) in provably-correct order, asserted against a spy.
- The domain value types (`WorkoutType`, `Configuration`) and the `AudioCuePlayer` seam the engine depends on.
- ≥90% coverage with the engine exhaustively covered; whole workouts verified in microseconds.

**Non-Goals:**
- Any SwiftUI view, view model, or count-up/down display mapping (change #6).
- The concrete `AVFoundation` player, `AVAudioSession`, and background/interruption handling (change #6).
- SwiftData persistence and configuration validation rules (change #4).
- Biometrics (Phase 2).

## Decisions

- **D1 — Tick-driven engine; extend the seam additively.** Add `ticks(interval:)` to `TimeSource` (guide §7.3). The engine subscribes to ticks; on each tick it reads `now` and runs a pure reducer (D4). `now`/`sleep(until:)` from change #1 are retained and unchanged (existing tests stay green); the engine itself does not use `sleep`. Alternative — drive transitions purely off `sleep(until: deadline)` — rejected because the ring needs continuous ~10–20 Hz `remaining` updates for smoothness, which a tick stream provides directly.
- **D2 — Reducer core, thin async driver.** The state machine is a **synchronous, pure** `process(at: Instant) -> [effect]` reducer over immutable engine state (current phase, phase deadline, paused-remaining, whether the warning fired this round). The async part is a thin loop: `for await instant in ticks { apply(process(at: instant)) }`. Rationale: the entire sequence — including coarse ticks and multi-deadline-in-one-tick — is unit-tested synchronously and deterministically with zero async coordination; only a couple of tests cover the loop wiring. This is what makes "verify a 12×3-minute workout in microseconds with exact cue order" (§14.1) straightforward. On each `process`, if `now` has crossed several deadlines, it loops transitions until caught up (handles the long-gap scenario).
- **D3 — Domain placement.** `WorkoutType` (pure, dependency-free) goes in **`ProRoundsFoundationUtilities`**, because both `ProRoundsDataConfig` and `ProRoundsDataSessions` already depend on Utilities — so sessions/performance can share it later without a Data→Data dependency. `Configuration` (the value type the config repository will own) goes in **`ProRoundsDataConfig`**. `Configuration.effectiveName` calls `WorkoutMath.autoName(workoutTypeName:…)` with `workoutType.displayName`, keeping the String-based calculator decoupled. Alternative — both types in DataConfig — rejected because it forces `DataSessions → DataConfig` in change #7.
- **D4 — Engine value types live with the engine.** `WorkoutPhase`, `WorkoutSnapshot` (and the internal engine state) live in `ProRoundsFeatureTimer` — they are engine concerns, not shared domain. The engine is `@MainActor`, exposing `private(set) var snapshot` (Observable) plus `start()`, `togglePause()`, `reset()`.
- **D5 — Warning-instant rule.** Warning fires when `now` first crosses `roundDeadline − warningLead`, once per round, only if `warningLead > 0`. If `warningLead ≥ roundDuration` (which config validation will forbid in change #4), the engine clamps the warning instant to the round start and fires once there. Count-up/down never reaches the engine (§7.6): snapshots carry both `remaining` and `elapsedInPhase`.

## Risks / Trade-offs

- **Async tick-loop coordination in the few integration tests** → Mitigation: keep the reducer synchronous (D2) so only loop-wiring needs async tests; those emit a fake tick then await one scheduler turn.
- **`ticks(interval:)` on the real source needs a repeating timer that stays monotonic and cancels cleanly** → Mitigation: back it with `ContinuousClock`-based async sleep in a loop yielding `now`; test approximate spacing only, exact behaviour lives in the fake.
- **Placing `WorkoutType` in Utilities stretches its "pure helpers" charter** → Mitigation: it is a pure, dependency-free value type; documented as the shared-primitive home. Revisit if a dedicated domain module is later warranted.
- **Reducer state must exactly model "no rest after final round" and 1-based indices** → Mitigation: this is the single most-tested behaviour; explicit scenarios for the boundary and off-by-one.

## Open Questions

- Real-source tick cadence — 10 Hz vs 20 Hz — is a display-smoothness tuning left to change #6 when the ring exists; the engine is cadence-agnostic (deadline-based), so this does not affect correctness here.
- Whether `sleep(until:)` stays on the seam long-term (currently unused by the engine) — keep it for now; remove only if no consumer emerges.

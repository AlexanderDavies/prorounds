## Context

Change #4 established the config data-layer pattern (generic container factory, `@ModelActor` repository, internal entity + mapper, in-memory testing). This change mirrors it for sessions and wires the workout's finish (change #6) to persist one. Sessions are the data the performance chart (#8) will read via `byWorkoutType()`.

## Goals / Non-Goals

**Goals:**
- A `Session` value type + `SessionRepository` (protocol + SwiftData impl + entity + mapper) with `save`/`all`/`byWorkoutType()`.
- Persist a session when a workout completes; surface a save failure with Retry.
- One shared on-disk store for configurations + sessions.

**Non-Goals:**
- The performance chart (#8) and any session-history list screen; partial-session capture.

## Decisions

- **D1 — Mirror the config repository (change #4).** `Session` (domain, DataSessions), internal `@Model SessionEntity`, `SessionMapper` (Duration↔whole seconds), `@ModelActor SwiftDataSessionRepository` with an injected container, `SessionStore.models` exposed type-erased. `all()` orders most-recent-first via a stored `date`. `byWorkoutType()` groups the mapped domain sessions by `WorkoutType`.
- **D2 — Session built by the view model on finish.** On the finished snapshot the `WorkoutViewModel` builds `Session(configuration:, date: now, roundsCompleted: config.rounds, activeDuration: rounds×roundDuration, totalDuration: config.totalDuration)`. Only a natural finish saves (roundsCompleted is always the full count); reset/leave saves nothing. Active duration = sum of round time (DESIGN §7.4), computed once (a small helper on `Session` or via `WorkoutMath`-style math kept in the model).
- **D3 — Save exactly once, surface failures.** The snapshot task saves on the first finished snapshot, guarded by a `didSave` flag (the stream may re-yield). Save runs in a `Task`; on failure the VM sets `saveFailed = true` and exposes `retrySave()`. The finished screen shows a "couldn't save" note + Retry when `saveFailed`. Never a bare `try?`-drop (§10.4/§10.5).
- **D4 — One shared store.** The composition root builds a single container for `ConfigurationStore.models + SessionStore.models` and hands it to both repositories, so config and sessions live in one on-device store.
- **D5 — Injection.** `WorkoutViewModel` gains a `SessionRepository` parameter; `ViewModelFactory.workout(_:)` passes `environment.sessionRepository`.

## Risks / Trade-offs

- **Double-save on repeated finished snapshots** → the `didSave` guard; a test drives to finish and asserts exactly one saved session.
- **Two entity types in one container** → both declared via each store's `models`; the config round-trip test already proves the mechanism, and a session on-disk round-trip test confirms it here.
- **Nondeterministic `date`** → tests assert type/rounds/durations, not the exact timestamp; ordering uses the stored date and is tested with two sequential saves.

## Open Questions

- A session-**history list** screen is out of MVP scope (persistence feeds the chart in #8); revisit if the product wants a raw history view.
- Whether "rounds completed" should ever be less than the configured count (partial sessions) — deferred; only full completions are saved for now.

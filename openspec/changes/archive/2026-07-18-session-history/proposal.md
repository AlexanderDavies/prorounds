## Why

A workout runs and shows a summary, but nothing is recorded. The app prompt requires every completed workout to be **saved as a session** and to persist across launches — and those sessions are the data the performance chart (change #8) will visualise. This change adds the session data layer and wires the workout's finish to persist one.

## What Changes

- Add the **`Session`** domain value type in `ProRoundsDataSessions`: date, workout type, the configuration used (name + rounds/round/rest/prep), rounds completed, and durations — including **active duration** (sum of round time, the chart's metric per DESIGN §7.4) and total elapsed.
- Add the **`SessionRepository`** boundary: the `Sendable` protocol (`save`, `all`, and `byWorkoutType()` grouping for the chart), a SwiftData `@ModelActor` implementation, an internal `SessionEntity` `@Model`, and an entity↔domain mapper — mirroring the config repository (change #4). Entities never escape.
- **Persist a session when a workout completes**: the `WorkoutViewModel` gains a `SessionRepository` and, on reaching the finished phase, builds and saves the session. If the save fails it is **not silently dropped** (§10.4) — the finished screen surfaces the failure with a Retry.
- Build the store with **both entity types** at the composition root (one on-disk container for configurations + sessions) and inject the `SessionRepository` into the workout view model.

Non-goals (deferred): the **Performance chart** that reads these sessions (change #8), a session **history list** screen (not in the MVP scope beyond persistence + the chart), and partial-session capture (only a naturally-completed workout is saved — leaving/resetting mid-workout saves nothing).

## Capabilities

### New Capabilities
- `session-model`: The `Session` domain value type and what a completed workout records (type, config, rounds completed, active + total durations, date).
- `session-repository`: The `SessionRepository` protocol and its SwiftData implementation (entity + mapper), including the `byWorkoutType()` grouping the chart consumes.

### Modified Capabilities
- `workout-runtime`: A completed workout is saved as a session; a save failure is surfaced with a Retry rather than dropped.

## Impact

- **Fleshes out** the `ProRoundsDataSessions` placeholder module (domain + repository + entity + mapper) and extends `ProRoundsFeatureTimer` (the workout view model saves on finish + a retry path).
- **Composition root**: the on-disk container is built for `ConfigurationStore.models + SessionStore.models` (one shared store); the `SessionRepository` is injected into the workout view model factory.
- Repository + save-on-finish unit-tested against an in-memory `ModelContainer` (fast macOS loop); an on-disk round-trip test confirms sessions survive relaunch.
- No new third-party dependencies; local-first preserved (on-device only, no network).

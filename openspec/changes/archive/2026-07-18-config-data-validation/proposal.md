## Why

The engine and design system are ready, but configurations only exist in memory. To pick, create, edit, and delete workouts (change #5) the app needs them **persisted on-device** behind a clean repository boundary, and the engine — which trusts its input — needs configurations **validated** at the edit boundary. This change delivers the persistence and validation layer so the config feature has a proven data foundation to build on.

## What Changes

- Give the domain `Configuration` a stable **identity** (`id: UUID`, `Identifiable`) so it can be saved, updated, and deleted by id.
- Add a **generic SwiftData container factory** in `ProRoundsFoundationPersistence` — on-disk (default) and in-memory (tests) — that takes its entity types as an argument, so the Foundation layer never imports a Data module (the entity types are injected by the composition root).
- Add the **`ConfigurationRepository`** boundary in `ProRoundsDataConfig`: the `Sendable` protocol (domain operations returning value-type `Configuration`s), a SwiftData-backed implementation (a `@ModelActor`), an internal `ConfigurationEntity` `@Model`, and an entity↔domain mapper. Entities and `ModelContext` never escape the repository. The list is ordered **most-recent-first** (§DESIGN decision).
- Add the **`ConfigurationValidator`** (guide §11): one validator enforcing `roundCount ≥ 1`, `roundDuration > 0`, `restDuration ≥ 0`, `prepDuration ≥ 0`, `0 ≤ warningLead < roundDuration`, returning typed errors. The engine assumes valid input and does not re-validate.

Non-goals (deferred): the config **list/editor UI** and view models (change #5, which consumes this repository + validator), the composition-root wiring into the app and the on-disk container at launch (change #5/app-wiring), `SessionRepository`/`SessionEntity` (change #7), and the `SettingsStore` (change #9). No UI, no app changes here.

## Capabilities

### New Capabilities
- `persistence-container`: The generic SwiftData `ModelContainer` factory in `ProRoundsFoundationPersistence` — default on-disk and in-memory variants, entity types injected — the single place the store is configured.
- `configuration-repository`: The `ConfigurationRepository` protocol and its SwiftData implementation (entity + mapper) — CRUD over `Configuration`s, most-recent-first, returning domain value types only.
- `configuration-validation`: The single `ConfigurationValidator` and its rules/typed errors, used at the create/edit boundary.

### Modified Capabilities
- `workout-configuration`: `Configuration` gains a stable `id: UUID` (`Identifiable`) so it can be persisted and addressed by the repository.

## Impact

- **Fleshes out** placeholder module `ProRoundsFoundationPersistence` (container factory) and extends `ProRoundsDataConfig` (`Configuration.id`, `ConfigurationRepository` + concrete + `ConfigurationEntity` + mapper + `ConfigurationValidator`).
- **Uses SwiftData** (Apple framework, on-device) — local-first invariant preserved (no network, no encryption needed for non-sensitive workout data, guide §6.2). Repositories tested against an **in-memory `ModelContainer`** on the fast macOS loop.
- **Adds `id` to `Configuration`** with a default `UUID()`, so existing engine/domain call sites and tests are unaffected.
- No new third-party dependencies; no UI; no `project.yml`/app change.

## Context

Change #2 introduced the in-memory `Configuration` domain type in `ProRoundsDataConfig`; the engine consumes it. This change makes configurations persistent and validated, behind the repository/validator boundaries of guide §6 and §11, tested against an in-memory `ModelContainer` on the fast macOS loop. It touches no UI — change #5 consumes this.

## Goals / Non-Goals

**Goals:**
- A `ConfigurationRepository` (protocol + SwiftData impl) with CRUD, most-recent-first ordering, returning only domain values.
- A generic `ModelContainer` factory in `ProRoundsFoundationPersistence` that keeps the Foundation layer free of any Data-layer reference.
- One `ConfigurationValidator` with the §11 rules and typed errors.
- `Configuration` gains `id` for identity.

**Non-Goals:**
- Config list/editor UI + view models (#5); composition-root wiring + on-disk container at launch (#5/app-wiring).
- `SessionRepository`/`SessionEntity` (#7), `SettingsStore` (#9).

## Decisions

- **D1 — Generic container factory; entity types injected.** Guide §6.2 shows `ModelContainer(for: ConfigurationEntity.self, …)` inside `ProRoundsFoundationPersistence`, but those entities live in the Data layer — referencing them there is an upward dependency (Foundation → Data). Instead `PersistenceContainer.make(for models: [any PersistentModel.Type], inMemory: Bool)` is generic; the composition root (App) and tests pass the entity types. `ProRoundsDataConfig` exposes them type-erased (`public static let models: [any PersistentModel.Type] = [ConfigurationEntity.self]`) so `ConfigurationEntity` itself stays `internal`. Foundation imports no Data module — the compile-enforced layering holds.
- **D2 — Repository is a `@ModelActor`.** SwiftData's `ModelContext` is not `Sendable`; the idiomatic seam is a `@ModelActor actor SwiftDataConfigurationRepository` that owns its context and returns `Sendable` `Configuration` values via the mapper. The container is injected (so config + later sessions share one store). The `ConfigurationRepository` protocol is `Sendable` with `async throws` methods.
- **D3 — Entity + mapping.** `@Model final class ConfigurationEntity` (internal) stores `@Attribute(.unique) id`, the params as `Int` seconds, `customName: String` (empty ⇒ no custom name), the raw workout-type string, and store-internal `createdAt`/`updatedAt: Date`. A `ConfigurationMapper` converts entity ↔ `Configuration` (`Duration` ↔ whole-second `Int` via `components.seconds`; whole-second precision matches the product). Entities never leave the actor.
- **D4 — Ordering via a store-internal timestamp.** `all()` sorts by `updatedAt` descending (set on every save) — "most-recent first" per the DESIGN decision — without putting a timestamp on the domain `Configuration`.
- **D5 — Upsert by id.** `save` fetches the entity for `id` (a `#Predicate`); found ⇒ mutate fields + bump `updatedAt`; absent ⇒ insert. `delete` fetches-then-deletes; a missing id is a no-op.
- **D6 — `Configuration` shape.** Add `id: UUID = UUID()` (`Identifiable`); `id` participates in `Equatable`. Keep the change-#2 field names (`rounds`, `customName?` + `effectiveName`) rather than the guide's illustrative `roundCount`/`name` — the engine already uses them, and `customName?` cleanly models the blank-name→auto-name fallback (the entity persists `customName`, empty string for nil).
- **D7 — Validator returns all violations.** `ConfigurationValidator.validate(_:) -> [ConfigurationValidationError]` (empty ⇒ valid) reports every broken rule so the editor can show them together. Rules are exactly §11's lower bounds plus `warningLead < roundDuration`; sensible upper bounds (max rounds/durations for the stepper) are a UI concern deferred to #5.

## Risks / Trade-offs

- **SwiftData under `swift test` on the macOS host** → Mitigation: use the in-memory `ModelContainer` (no disk); the package already targets macOS 14 / iOS 17 where SwiftData exists. If a host quirk appears, the repository tests can move to the iOS-sim runner, but in-memory SwiftData on macOS is expected to work.
- **`@ModelActor` + `#Predicate` on `UUID`** can be finicky (predicate support varies) → Mitigation: if a `UUID` predicate misbehaves, fetch all and match in-actor (small data set); keep the mapper the single translation point.
- **Whole-second `Duration` ↔ `Int`** loses sub-second precision → Acceptable: all product durations are whole seconds; documented in the mapper.

## Open Questions

- Upper bounds for rounds/durations (stepper ranges) — deferred to change #5's editor; the validator enforces only the §11 correctness rules now.
- Whether "most-recent" should also bump when a workout is *run* (not just edited) — the timestamp is in the entity, so change #6 can bump it on run; out of scope here.

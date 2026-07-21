## 1. Configuration identity

- [x] 1.1 Write failing tests: a `Configuration` built without an id gets a fresh `id`; two round-tripped copies keep the same id (spec: workout-configuration)
- [x] 1.2 Add `id: UUID = UUID()` to `Configuration` (`Identifiable`, id in `Equatable`); confirm existing engine/domain tests still pass — green

## 2. Persistence container (ProRoundsFoundationPersistence)

- [x] 2.1 Write failing tests: an in-memory container builds for a given entity-type list; the module imports no `ProRoundsData*` (spec: persistence-container)
- [x] 2.2 Implement `PersistenceContainer.make(for models: [any PersistentModel.Type], inMemory: Bool)` (default on-disk + in-memory) — green
- [x] 2.3 Confirm the module has no Data import (grep/build) — the Foundation layer stays generic (spec: persistence-container)

## 3. Configuration entity, mapper & repository (ProRoundsDataConfig)

- [x] 3.1 Add internal `@Model ConfigurationEntity` (unique id, Int-second params, customName, workout-type raw, createdAt/updatedAt) and a public type-erased `models` list; keep the entity `internal`
- [x] 3.2 Write failing tests for `ConfigurationMapper` entity↔domain round-trip (Duration↔Int seconds, customName empty⇒nil) (spec: configuration-repository)
- [x] 3.3 Implement the mapper — green
- [x] 3.4 Define the `Sendable ConfigurationRepository` protocol (all / save / delete, domain values only)
- [x] 3.5 Write failing repository tests against an in-memory container: save-new inserts; save-existing-id updates (no duplicate); delete removes; delete-absent is a no-op; list is most-recent-first (spec: configuration-repository)
- [x] 3.6 Implement `@ModelActor SwiftDataConfigurationRepository` (injected container, upsert-by-id, updatedAt bump, ordered listing) — green
- [x] 3.7 Confirm no entity/`ModelContext` escapes the repository boundary (API review)

## 4. Configuration validation (ProRoundsDataConfig)

- [x] 4.1 Write failing tests for `ConfigurationValidator`: valid config → no errors; rounds<1, roundDuration≤0, negative rest/prep, warningLead≥round each flagged; zero warningLead valid; multiple violations all reported (spec: configuration-validation)
- [x] 4.2 Implement `ConfigurationValidator` + typed `ConfigurationValidationError` (all §11 rules, returns every violation) — green

## 5. Verification

- [x] 5.1 `./scripts/test.sh` green (repository tests run against in-memory SwiftData on macOS); coverage gate passes with the engine included
- [x] 5.2 `./scripts/lint.sh` strict clean; module graph compiles (FoundationPersistence imports no Data; DataConfig imports no Feature)
- [x] 5.3 `openspec validate config-data-validation` clean; README updated (data layer now real)

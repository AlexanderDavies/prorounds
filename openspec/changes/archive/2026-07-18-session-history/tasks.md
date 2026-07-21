## 1. Session domain model (ProRoundsDataSessions)

- [x] 1.1 Add the `ProRoundsDataSessionsTests` test target to `Package.swift`
- [x] 1.2 Write failing tests for `Session`: captures type/name/rounds/durations; `activeDuration` = rounds × round time (rest/prep excluded); a convenience init from `Configuration` (spec: session-model)
- [x] 1.3 Implement the `Session` value type (`Sendable`/`Identifiable`) with a primitive init. **Placement change:** the `Configuration`-based init lives as `Session(completed:at:)` in `ProRoundsFeatureTimer` (not DataSessions) because `DataSessions` must not import `DataConfig` (no Data→Data dependency); it is exercised by the WorkoutViewModel save tests — green

## 2. Session repository (ProRoundsDataSessions)

- [x] 2.1 Add internal `@Model SessionEntity` (unique id, workout-type raw, name, Int-second durations, roundsCompleted, date) + a public type-erased `SessionStore.models` + `makeContainer`; keep the entity internal
- [x] 2.2 Write failing tests for `SessionMapper` entity↔domain round-trip (spec: session-repository)
- [x] 2.3 Implement the mapper — green
- [x] 2.4 Define the `Sendable SessionRepository` protocol (`save`, `all`, `byWorkoutType()`)
- [x] 2.5 Write failing repository tests against an in-memory container: save inserts; list is most-recent-first; `byWorkoutType()` buckets correctly; on-disk round-trip survives a fresh container (spec: session-repository)
- [x] 2.6 Implement `@ModelActor SwiftDataSessionRepository` — green

## 3. Save on finish (ProRoundsFeatureTimer)

- [x] 3.1 Write failing `WorkoutViewModel` tests (real in-memory session repo): finishing saves exactly one session with the right fields; reset-before-finish saves nothing; a failing repo sets `saveFailed` and `retrySave()` re-attempts (spec: workout-runtime)
- [x] 3.2 Add a `SessionRepository` dependency to `WorkoutViewModel`; save the built `Session` on the first finished snapshot (guarded), exposing `saveFailed` + `retrySave()` — green
- [x] 3.3 Show a "couldn't save · Retry" affordance in `WorkoutContentView`'s finished state when `saveFailed`

## 4. Composition & verification

- [x] 4.1 Composition root: build one container for `ConfigurationStore.models + SessionStore.models`; add `SwiftDataSessionRepository`; `ViewModelFactory.workout(_:)` injects it
- [x] 4.2 `./scripts/test.sh` + `./scripts/coverage.sh` green (engine included); `./scripts/lint.sh` strict clean; `./scripts/snapshot.sh` green (add a finished-save-failed snapshot if the finished layout changed)
- [x] 4.3 Save-on-finish verified by WorkoutViewModel tests (drive to finish over a real in-memory SwiftDataSessionRepository → exactly one session with correct fields; reset saves nothing; failure→retry) + the repository on-disk round-trip test (survives a fresh container). **Not via XCUITest:** there is no session UI to observe a saved session yet (history/chart is #8), and driving a full real-time workout in XCUITest isn't practical; the existing XCUITest confirms the flow still works after the composition change
- [x] 4.4 Module graph compiles (DataSessions imports no Feature; FeatureTimer imports no sibling Feature); `openspec validate session-history` clean; README updated

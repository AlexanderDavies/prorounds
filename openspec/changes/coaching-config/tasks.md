## 1. Domain: the coaching level

- [x] 1.1 Write failing tests for `CoachingLevel`: beginner is the only case, and it round-trips through its raw value (a rename must fail loudly, since the raw value is what is persisted)
- [x] 1.2 Add `CoachingLevel` to `ProRoundsDataConfig`, and a test asserting `WorkoutType` still has exactly its five cases — coached variants stay out of that enum
- [x] 1.3 Write failing tests: `Configuration` defaults to no coaching, and two configurations differing only in coaching level report the same `totalDuration` and the same auto-name
- [x] 1.4 Add `coachingLevel: CoachingLevel?` to `Configuration` with a defaulted initialiser parameter, so every existing construction site still compiles

## 2. Persistence and the first migration

This is the only irreversible part of the change. SwiftData is the user's sole copy of their
configurations — no backend, no export — so a dropped record is gone.

- [x] 2.1 Write the failing migration test **first**, and build its fixture with the *pre-change* entity shape: write a store with several configurations, close it, reopen under the new schema, and assert every record is present, reads back uncoached, and every other field is unchanged. A fixture built from the new model would prove nothing
- [x] 2.2 Assert a migrated record is still writable: edit one and save it
- [x] 2.3 Add `coachingLevelRaw: String?` to `ConfigurationEntity` — **optional**, to stay in lightweight-migration territory; a non-optional attribute without a default fails to open an existing store
- [x] 2.4 Map the field in `ConfigurationMapper` both ways, with nil ↔ no coaching, and a test pinning the exact persisted string for beginner
- [x] 2.5 Write failing round-trip tests through `ConfigurationRepository` for a coached and an uncoached configuration, then make them pass
- [x] 2.6 Confirm an unrecognised stored level string degrades to no coaching rather than throwing — a forward-compatibility path for a store written by a later build

## 3. Validation

- [x] 3.1 Write failing tests: coaching is valid for Shadow Boxing and Heavy Bag, rejected for Skipping, Speed Ball and Sparring, and always valid when absent
- [x] 3.2 Add the coaching rule to `ConfigurationValidator` with a new `ConfigurationValidationError` case
- [x] 3.3 Test that a coaching violation is reported alongside other violations, consistent with reporting all of them together
- [x] 3.4 Expose which workout types support coaching as a single source both the validator and the editor read, so the two cannot disagree

## 4. Settings

- [x] 4.1 Write failing tests for the two new preferences on the in-memory store: defaults are numbers and non-minimal
- [x] 4.2 Add `namingConvention` and `minimalRunningScreen` to the `SettingsStore` protocol, the `UserDefaults` store, and the in-memory fake
- [x] 4.3 Write failing durability tests: set each, construct a new store over the same defaults, read the new value back
- [x] 4.4 Test that changing the naming convention rewrites no configuration and leaves stored configurations comparing equal

## 5. Entitlement seam

- [ ] 5.1 Write failing tests for an `EntitlementStore` protocol: the shipped implementation reports coaching unlocked, and a test double can report it locked
- [ ] 5.2 Add the protocol and the unlocked implementation. Return a plain `Bool` **synchronously** — no `async`, no publisher — so the seam is structurally incapable of stalling a round
- [ ] 5.3 Assert the seam links no StoreKit and makes no network call, keeping the local-first invariant
- [ ] 5.4 Assert the timer engine takes no entitlement store and exposes no way to consult one
- [ ] 5.5 Assert configurations and preferences are unaffected by a locked entitlement, so nothing is lost when it is later granted

## 6. Config editor and list

- [ ] 6.1 Write failing view-model tests: the Coaching section is offered for scripted workout types and absent for the others
- [ ] 6.2 Add the Coaching section to the editor, driven by the shared "supports coaching" source from 3.4
- [ ] 6.3 Write a failing test: changing to an unscripted workout type clears the coaching level, so an invalid combination cannot reach save
- [ ] 6.4 Test that saving an invalid coaching combination is blocked and surfaced through the existing validate-before-persist path
- [ ] 6.5 Add the coaching badge to `ConfigCard`, naming the level rather than merely marking coaching, so a second level needs no redesign
- [ ] 6.6 Test that an uncoached card renders unchanged

## 7. Settings screen and composition root

- [ ] 7.1 Write failing view-model tests for the two new Settings rows, writing through the store
- [ ] 7.2 Add the rows, showing each naming-convention option with an example of what the coach says
- [ ] 7.3 Link `ProRoundsFoundationCoaching` into the app target in `project.yml` and regenerate the Xcode project
- [ ] 7.4 Construct the `EntitlementStore` in `AppEnvironment` and inject it; test that exactly one is built and nothing constructs its own
- [ ] 7.5 Test that the coaching catalog and both scripts load from the module bundle in the app target's context

## 8. Gates and docs

- [ ] 8.1 `scripts/lint.sh` clean
- [ ] 8.2 `scripts/test.sh` green
- [ ] 8.3 `scripts/coverage.sh` at or above 90% — the editor's conditional section and the type-change clearing need view-model tests, not just snapshots
- [ ] 8.4 Re-record affected design-system snapshots for the `ConfigCard` badge. **Blocked on this machine:** Command Line Tools lacks XCTest, so snapshot targets do not build; note it and hand off, or run under full Xcode
- [ ] 8.5 Update `README.md` and `docs/COACHING_UX_BRIEF.md` per CLAUDE.md §0.3, recording that Decisions 2, 4 and 5 are now implemented

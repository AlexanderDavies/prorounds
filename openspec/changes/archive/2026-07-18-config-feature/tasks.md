## 1. Display mapping & module setup

- [x] 1.1 Add the `ProRoundsFeatureConfigTests` test target to `Package.swift`
- [x] 1.2 Add `ConfigRowDisplay` + a mapper from `Configuration` (effective name, metadata line "N × m:ss · m:ss rest", total text, workout-type SF Symbol with fallback) using the single-source calculators; unit-test it (spec: config-list)
- [x] 1.3 Add the `TimerRoute` enum (`.configEditor(Configuration.ID?)`) for the create/edit distinction

## 2. Config list

- [x] 2.1 Write failing tests for `ConfigListViewModel` (over an in-memory `SwiftDataConfigurationRepository`): load maps rows most-recent-first; empty when none; delete removes and persists (spec: config-list)
- [x] 2.2 Implement `@MainActor @Observable ConfigListViewModel` (load, delete, intents to open create/edit) — green
- [x] 2.3 Build `ConfigListView` (dumb): `ConfigCard` rows, empty state, `+` toolbar, swipe/context delete, card tap → editor; compose design tokens/components (spec: config-list)

## 3. Config editor

- [x] 3.1 Write failing tests for `ConfigEditorViewModel`: draft edits recompute live total + auto-name; save-invalid surfaces errors and does not persist; save-valid persists (insert & update); cancel discards; delete removes (spec: config-editor)
- [x] 3.2 Implement `ConfigurationDraft` + `@MainActor @Observable ConfigEditorViewModel` (live preview via `WorkoutMath`/`DurationFormat`, validate via `ConfigurationValidator`, per-field error mapping, save/cancel/delete) — green
- [x] 3.3 Build `ConfigEditorView` (dumb): workout-type picker + value fields in spec order (bounds per design D6), live total/auto-name, Save/Cancel toolbar, Delete when editing (spec: config-editor)

## 4. Composition root & app wiring

- [x] 4.1 Add `AppEnvironment` (on-disk `ModelContainer` via `PersistenceContainer` for `ConfigurationStore.models` + `SwiftDataConfigurationRepository`) and `ViewModelFactory` in the app target (spec: app-composition)
- [x] 4.2 Wire the Timer tab to `ConfigListView` inside a `NavigationStack`, editor as a `.sheet`; inject via the factory (spec: app-shell)
- [x] 4.3 Update `project.yml` — app target depends on `ProRoundsFeatureConfig`, `ProRoundsDataConfig`, `ProRoundsFoundationPersistence`, `ProRoundsDesignSystem`; `xcodegen generate`

## 5. Snapshots & tooling

- [x] 5.1 Broaden `coverage.sh` exclusion to `*View.swift` (view models/mappers stay counted; engine included) (guide §14.4)
- [x] 5.2 Add screen snapshot tests (light + dark) for the list empty state, a populated list, and the editor (spec: config-list / config-editor)

## 6. Verification

- [x] 6.1 `./scripts/test.sh` + `./scripts/coverage.sh` green (view models counted, views excluded); `./scripts/lint.sh` strict clean; `./scripts/snapshot.sh` green
- [x] 6.2 Verified the flow (no tap tooling — idb/simctl can't tap): app launches to the empty state in the simulator (screenshot, dark); populated list + editor rendered via seeded screen snapshots (light + dark) showing correct rows/ordering/live-preview; on-disk persistence proven by a hermetic round-trip test (a fresh container reads what a prior one wrote); create/edit/delete logic proven by view-model tests against the real repository. Interactive tap-through (create→edit→delete by tapping) would need an XCUITest target — deferred to when #6's workout flow makes UI-flow testing worthwhile.
- [x] 6.3 Module graph compiles (FeatureConfig imports no sibling Feature); `openspec validate config-feature` clean; README updated

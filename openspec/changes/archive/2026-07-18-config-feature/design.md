## Context

First feature with UI. The data layer (`ConfigurationRepository` + `ConfigurationValidator`), the engine's domain types, and the design-system components are all in place. This change composes them into the Configurations list + editor and stands up the composition root that injects the on-disk store — the wiring every later feature reuses. Follows guide §3 (dumb views, `@MainActor @Observable` view models, display mapping, enum routes) and §5 (constructor injection, one composition root).

## Goals / Non-Goals

**Goals:**
- A working Configurations list (cards, empty state, delete) and create/edit editor (fields in spec order, live total/auto-name, validation, save/cancel/delete).
- The composition root: `AppEnvironment`, on-disk `ModelContainer` + `SwiftDataConfigurationRepository`, and a `ViewModelFactory`; the Timer tab shows the list.
- View models unit-tested against an in-memory store; screens verified in the simulator + light/dark snapshots.

**Non-Goals:**
- Launching a workout from a config (running screen → #6); sessions/performance (#7/#8); settings/count-direction/theme (#9).
- Promoting the editor's value field into a `ProRoundsDesignSystem` component (rule of three — only one consumer today).

## Decisions

- **D1 — Module split.** `ProRoundsFeatureConfig` holds the views, `@MainActor @Observable` view models, display-model mapping, and the editor draft. The **app target** holds the composition root: `AppEnvironment` (concrete deps), the on-disk container (`PersistenceContainer.make(for: ConfigurationStore.models, inMemory: false)`) + `SwiftDataConfigurationRepository`, and `ViewModelFactory`. The app target imports `ProRoundsFeatureConfig` + `ProRoundsDataConfig` + `ProRoundsFoundationPersistence` + `ProRoundsDesignSystem` (added to `project.yml`).
- **D2 — View models over protocols; tested against the real repo + in-memory container.** `ConfigListViewModel` and `ConfigEditorViewModel` depend on `ConfigurationRepository` (protocol) and, for the editor, `ConfigurationValidator`. Per guide §5.5 the test seam is `SwiftDataConfigurationRepository` with an in-memory container — no separate fake repository needed. State is `private(set)`; views forward intents.
- **D3 — Editor uses a mutable draft.** `ConfigEditorViewModel` holds a `ConfigurationDraft` (mutable fields) and computes the live total and auto-name from it via the single-source `WorkoutMath`/`DurationFormat`. Save builds a `Configuration` (preserving the id when editing), runs `ConfigurationValidator`, maps any errors to per-field messages, and persists only when valid.
- **D4 — Editor presented as a sheet.** For a two-screen feature, the editor is a `.sheet(item:)` from the list (create via a `+` toolbar item, edit via card tap) with Cancel/Save in the sheet toolbar and Delete when editing. The full enum-route `NavigationStack` router (guide §3.4) is formalized in #6 when the running route joins; a `TimerRoute` enum is introduced now for the create/edit distinction.
- **D5 — Card tap opens the editor (temporary).** The running screen doesn't exist yet, so tapping a card edits it. Change #6 re-points the primary tap to launch the workout and moves Edit to a swipe/secondary action.
- **D6 — Value-field bounds (product defaults).** rounds 1–99; round time 5s–60m; rest 0–30m; prep 0–10m; warning lead 0–120s. The validator still enforces `warningLead < roundDuration` regardless. Durations edited via minute/second steppers.
- **D7 — Workout-type icon in the display mapper.** The `ConfigRowDisplay` mapper picks an SF Symbol per `WorkoutType` (DESIGN §5 suggestions: boxing/jumprope/kickboxing/circle.circle/martial.arts) with a safe fallback if a glyph is unavailable on the deployment target.
- **D8 — Coverage.** `coverage.sh` broadens its exclusion to `*View.swift` (guide §14.4 — declarative views), so **view models and mappers stay counted** while views don't. The engine remains included.

## Risks / Trade-offs

- **`@MainActor @Observable` view-model testing** → straightforward with Swift Testing `@MainActor` suites; assert on `private(set)` display state after intents, against the in-memory repo.
- **First `project.yml` change + app build** → regenerate and build for the simulator as part of verification; the app target's new product deps are the only project change.
- **Screen snapshots add references** → keep to a few high-value states (list empty, list populated, editor) in light+dark; components already carry their own snapshots.
- **On-disk store during tests** → tests always use the in-memory container; only the app uses the on-disk one (verified by relaunch in the simulator).

## Open Questions

- Exact value-field bounds (D6) are sensible defaults — easy to adjust if the product owner prefers different caps.
- Whether the editor should be a sheet vs a pushed route (D4) — sheet chosen for simplicity now; revisit in #6 with the running route.

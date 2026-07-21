## Why

The engine, design system, and config data layer are all proven — but nothing is on screen. This change delivers the app's first real feature: browsing, creating, editing, and deleting workout configurations. It also stands up the **composition root** (the object graph + on-disk store, injected downward), which every later feature plugs into. After this, the Timer tab is a working screen instead of a placeholder.

## What Changes

- Build **`ProRoundsFeatureConfig`** — the presentation for configurations, following the guide §3 pattern (dumb `*View`s, `@MainActor @Observable` view models over injected protocols, display-model mapping):
  - **Configurations list** — a `ConfigListViewModel` over `ConfigurationRepository`, rendered with the design-system `ConfigCard`; most-recent-first; an empty state ("No rounds yet"); delete via swipe/context menu; a `+` to create.
  - **Config editor** — a `ConfigEditorViewModel` over the repository + `ConfigurationValidator`: workout-type picker and value fields (rounds, round/rest/prep time, warning lead) in spec order, a **live total-time and auto-name preview** (single-source calculators), Save (validated — invalid input surfaces per-field errors and does not save), Cancel, and Delete when editing an existing one.
  - A `TimerRoute` enum + the tab's `NavigationStack` wiring (list → editor).
- Stand up the **composition root** in the app target: an `AppEnvironment` holding the concrete dependencies, the **on-disk `ModelContainer`** (built via `PersistenceContainer` for `ConfigurationStore.models`) and the `SwiftDataConfigurationRepository`, and a `ViewModelFactory` that builds view models — so features never construct repositories themselves (guide §5.3).
- **Wire the Timer tab** to the config list (replacing its placeholder), and add `ProRoundsFeatureConfig` (and its concrete-repo/persistence deps) to the app target in `project.yml` (regenerated).

Non-goals (deferred): launching a **workout** from a config — the running screen is change #6, which will re-point the card's primary tap and move Edit to a secondary affordance (in this change, tapping a card opens the editor). Sessions/performance (#7/#8), settings + count-direction/theme (#9), and promoting the editor's value field into a reusable `ProRoundsDesignSystem` component (deferred until a second consumer exists — rule of three).

## Capabilities

### New Capabilities
- `config-list`: The Configurations list screen — view model over the repository, `ConfigCard` rows, most-recent-first ordering, empty state, and delete.
- `config-editor`: The create/edit editor — value fields in spec order, live total/auto-name preview, validation surfacing, and save/cancel/delete.
- `app-composition`: The composition root — `AppEnvironment`, the on-disk container + concrete repository, and the `ViewModelFactory` that injects them into view models.

### Modified Capabilities
- `app-shell`: The Timer tab's root becomes the Configurations list inside a `NavigationStack` (was a placeholder); the shell now composes an injected `ViewModelFactory`.

## Impact

- **Fleshes out** `ProRoundsFeatureConfig` (views, view models, display mapping, router) and the **app target** (composition root, `AppEnvironment`, `ViewModelFactory`, on-disk store).
- **First `project.yml` change since bootstrap** — the app target gains `ProRoundsFeatureConfig`, `ProRoundsDataConfig`, `ProRoundsFoundationPersistence`, `ProRoundsDesignSystem` product deps; **regenerate the project** (`xcodegen generate`).
- **First on-disk persistence at runtime** — configurations survive relaunch. Local-first preserved (no network).
- View models unit-tested against an in-memory `ModelContainer` (fast macOS loop); the screens verified in the simulator (create → list → edit → delete), light and dark.
- No new third-party dependencies.

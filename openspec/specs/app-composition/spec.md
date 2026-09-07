# app-composition Specification

## Purpose
TBD - created by archiving change config-feature. Update Purpose after archive.
## Requirements
### Requirement: Single composition root builds the object graph

The app SHALL construct its dependency graph in one place (the app entry / composition root) and inject it downward by constructor injection — no singletons, globals, or service locator. The on-disk `ModelContainer` and the concrete `ConfigurationRepository` SHALL be created here, once.

#### Scenario: Dependencies are built once and injected

- **WHEN** the app launches
- **THEN** the composition root builds the on-disk container and repository and passes them down; no feature constructs its own repository or container

### Requirement: ViewModelFactory constructs view models

A `ViewModelFactory` (holding the app environment) SHALL build the feature view models with their injected dependencies, so views receive a ready view model and never assemble collaborators themselves.

#### Scenario: The factory yields a wired view model

- **WHEN** a feature needs its screen's view model
- **THEN** the factory returns one already wired with the repository (and validator) from the environment

### Requirement: Persistence survives relaunch

Configurations saved through the composition-root repository SHALL be written to the on-device store and be present after the app is relaunched.

#### Scenario: A saved configuration is still there after relaunch

- **WHEN** a configuration is saved and the app is relaunched
- **THEN** the configuration is listed again from the on-disk store

### Requirement: The composition root owns the entitlement store
The single composition root SHALL construct the entitlement store and inject it, consistent with
every other dependency. No feature SHALL construct one itself or reach a global.

#### Scenario: The entitlement store is built once and injected
- **WHEN** the object graph is built
- **THEN** exactly one entitlement store SHALL be constructed and passed to the types that need it

#### Scenario: Swapping the implementation is a composition-root change
- **WHEN** the entitlement implementation is replaced
- **THEN** only the composition root SHALL change, with no edit to any feature or data type

### Requirement: The app links the coaching module
The app target SHALL link `ProRoundsFoundationCoaching`, so the catalog and scheduler are reachable
from the running app rather than test-only.

#### Scenario: The coaching catalog loads in the app
- **WHEN** the app runs
- **THEN** the coaching catalog and both scripts SHALL load from the module bundle without error

### Requirement: The composition root builds the coaching cue planner
The composition root SHALL construct the planner from the coaching catalog, the settings store and
the entitlement store, and inject it into the workout runtime. No feature SHALL construct one itself.

#### Scenario: The planner is built once and injected
- **WHEN** the object graph is built
- **THEN** one planner SHALL be constructed and passed to the runtime that needs it

#### Scenario: A catalog that fails to load degrades to no coaching
- **WHEN** the coaching catalog cannot be loaded at launch
- **THEN** the app SHALL start with coaching unavailable rather than fail to launch, because a
  content problem must never cost the user their timer

#### Scenario: The timer module still cannot reach coaching
- **WHEN** the object graph is built
- **THEN** the timer module SHALL still have no dependency on the coaching module, the planner
  reaching it only through the injected seam


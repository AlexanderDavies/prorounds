## ADDED Requirements

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

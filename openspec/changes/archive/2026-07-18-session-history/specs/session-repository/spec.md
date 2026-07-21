## ADDED Requirements

### Requirement: Repository saves and lists sessions as domain values

The system SHALL define a `Sendable` `SessionRepository` protocol exposing `save` and `all`, accepting and returning the value-type `Session` only. The SwiftData `@Model` entity and `ModelContext` SHALL never cross the boundary; features depend on the protocol.

#### Scenario: A saved session is listed back

- **WHEN** a session is saved into an empty store and then listed
- **THEN** exactly that session is returned, as a `Session` value (no entity leaks)

#### Scenario: Sessions are listed most-recent-first

- **WHEN** two sessions are saved in sequence and listed
- **THEN** the most recent is first

### Requirement: Sessions grouped by workout type

The repository SHALL provide `byWorkoutType()` returning the sessions grouped by their `WorkoutType`, so the performance chart can plot a line per type without regrouping in the view.

#### Scenario: Grouping buckets sessions by type

- **WHEN** sessions of two workout types are saved and `byWorkoutType()` is read
- **THEN** each type maps to its own sessions and no session appears under the wrong type

### Requirement: Sessions persist across relaunch

Saved sessions SHALL be written to the on-device store and be present after the app is relaunched.

#### Scenario: A saved session survives a fresh container

- **WHEN** a session is saved and a fresh container is opened at the same store location
- **THEN** the session is listed again

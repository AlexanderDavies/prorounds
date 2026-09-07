## MODIFIED Requirements

### Requirement: Persisted preferences with sensible defaults

The system SHALL provide a `SettingsStore` — a small, synchronous `Sendable` protocol — for the non-sensitive preferences: warning sound, count direction, appearance (`ColorSchemePreference` = light / dark / system), the coaching naming convention (numbers / names), and whether the running screen is minimal. Unset preferences SHALL return sensible defaults (count down, system appearance, punches named by number, and a non-minimal screen).

#### Scenario: Defaults on a fresh store

- **WHEN** a fresh store is read before anything is set
- **THEN** count direction is count down and appearance is system

#### Scenario: Coaching defaults on a fresh store

- **WHEN** a fresh store is read before anything is set
- **THEN** the naming convention is numbers and the minimal screen is off

## ADDED Requirements

### Requirement: Coaching preferences are person-level, not per-workout
The naming convention and the minimal-screen preference SHALL be stored once for the person, not on
a `Configuration`. They describe how the user wants to be coached and read, not what a given workout
is.

#### Scenario: The convention applies to every coached workout
- **WHEN** the naming convention is set to names
- **THEN** every coached workout SHALL use it, with no per-configuration override

#### Scenario: Changing the convention does not modify configurations
- **WHEN** the naming convention is changed
- **THEN** no stored configuration SHALL be rewritten, and none SHALL compare unequal as a result

#### Scenario: Both preferences are durable
- **WHEN** either preference is changed and a new store over the same defaults is read
- **THEN** it SHALL return the new value

#### Scenario: The in-memory fake carries them too
- **WHEN** a test constructs the in-memory store
- **THEN** it SHALL expose both preferences with the same defaults, so no test needs `UserDefaults`

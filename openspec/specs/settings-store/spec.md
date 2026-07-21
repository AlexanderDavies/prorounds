# settings-store Specification

## Purpose
TBD - created by archiving change settings. Update Purpose after archive.
## Requirements
### Requirement: Persisted preferences with sensible defaults

The system SHALL provide a `SettingsStore` — a small, synchronous `Sendable` protocol — for the non-sensitive preferences: warning sound, count direction, and appearance (`ColorSchemePreference` = light / dark / system). Unset preferences SHALL return sensible defaults (count down, and system appearance).

#### Scenario: Defaults on a fresh store

- **WHEN** a fresh store is read before anything is set
- **THEN** count direction is count down and appearance is system

### Requirement: Changes are durable

The `UserDefaults`-backed store SHALL persist a changed preference so a store reading the same defaults later returns the new value.

#### Scenario: A changed preference is read back

- **WHEN** the appearance is set to dark and a new store over the same defaults is read
- **THEN** it returns dark

### Requirement: In-memory fake for tests

The system SHALL provide an in-memory `SettingsStore` so features can be tested without touching `UserDefaults`.

#### Scenario: The fake round-trips values without disk

- **WHEN** a value is set on the in-memory store and read back
- **THEN** it returns the set value and nothing is written to `UserDefaults`


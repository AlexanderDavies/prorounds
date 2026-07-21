# workout-configuration Specification

## Purpose
TBD - created by archiving change round-timer-engine. Update Purpose after archive.
## Requirements
### Requirement: Workout type enumeration

The system SHALL define a `WorkoutType` enumeration with exactly the five types, presented in this order: Shadow Boxing, Skipping, Heavy Bag, Speed Ball, Sparring. Each SHALL expose a stable display name.

#### Scenario: Types are ordered as specified

- **WHEN** the ordered `WorkoutType` cases are listed
- **THEN** they are Shadow Boxing, Skipping, Heavy Bag, Speed Ball, Sparring in that order

#### Scenario: Each type has a display name

- **WHEN** the display name of `.heavyBag` is read
- **THEN** it is "Heavy Bag"

### Requirement: Configuration value type

The system SHALL define an immutable `Configuration` value type carrying the workout type, number of rounds, round duration, rest duration, prep duration, round-end warning lead, and an optional custom name. It SHALL expose its total duration and its effective (custom-or-auto) name through the single-source calculators, and SHALL be `Sendable`/`Equatable`. Its total duration is the workout time (rounds + rest), excluding prep. Persistence and validation rules are out of scope for this capability.

#### Scenario: Total duration uses the single-source calculator

- **WHEN** a configuration of 12 rounds × 3:00 with 1:00 rest and 0:10 prep is asked for its total duration
- **THEN** it returns 47:00 (12×round + 11×rest), matching the shared calculator — prep excluded, no rest after the final round

#### Scenario: Effective name falls back to the auto name

- **WHEN** a configuration has no custom name (empty/nil)
- **THEN** its effective name is the auto-generated name derived from type, rounds, round, and rest

#### Scenario: Custom name is preserved

- **WHEN** a configuration has a non-empty custom name
- **THEN** its effective name is that custom name

### Requirement: Configuration has a stable identity

The `Configuration` value type SHALL carry a stable `id: UUID` and conform to `Identifiable`, so it can be persisted, updated in place, and deleted by id. The id SHALL default to a fresh value when not supplied, so existing in-memory construction (e.g. by the engine and its tests) is unaffected.

#### Scenario: A configuration keeps its id across a round-trip

- **WHEN** a configuration is created, saved, and read back
- **THEN** the read-back configuration has the same `id`

#### Scenario: Identity does not disturb existing construction

- **WHEN** a configuration is constructed without specifying an id
- **THEN** it receives a fresh unique id and its other fields and derived values are unchanged


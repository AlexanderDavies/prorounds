## MODIFIED Requirements

### Requirement: Configuration value type

The system SHALL define an immutable `Configuration` value type carrying the workout type, number of rounds, round duration, rest duration, prep duration, round-end warning lead, an optional custom name, and an optional coaching level. It SHALL expose its total duration and its effective (custom-or-auto) name through the single-source calculators, and SHALL be `Sendable`/`Equatable`. Its total duration is the workout time (rounds + rest), excluding prep. Persistence and validation rules are out of scope for this capability.

#### Scenario: Total duration uses the single-source calculator

- **WHEN** a configuration of 12 rounds × 3:00 with 1:00 rest and 0:10 prep is asked for its total duration
- **THEN** it returns 47:00 (12×round + 11×rest), matching the shared calculator — prep excluded, no rest after the final round

#### Scenario: Effective name falls back to the auto name

- **WHEN** a configuration has no custom name (empty/nil)
- **THEN** its effective name is the auto-generated name derived from type, rounds, round, and rest

#### Scenario: Custom name is preserved

- **WHEN** a configuration has a non-empty custom name
- **THEN** its effective name is that custom name

#### Scenario: Coaching is off by default

- **WHEN** a configuration is created without specifying a coaching level
- **THEN** its coaching level is nil, meaning coaching is off

#### Scenario: Coaching does not affect derived values

- **WHEN** two configurations are identical except that one has a coaching level and the other does not
- **THEN** they SHALL report the same total duration and the same auto-generated name — coaching is not part of the workout's identity or arithmetic

## ADDED Requirements

### Requirement: Coaching levels are a closed enumeration
The system SHALL model the coaching level as an enumeration whose only v1 case is beginner, with nil
meaning coaching is off. Adding a level SHALL be an additive change requiring no change to
`WorkoutType`.

#### Scenario: Beginner is the only level in v1
- **WHEN** the available coaching levels are enumerated
- **THEN** exactly one is offered, and it is beginner

#### Scenario: Coaching is not a workout type
- **WHEN** the workout types are enumerated
- **THEN** they SHALL remain the five shipped values with no coached variants, because that
  enumeration is load-bearing for auto-naming, the session model and the chart legend

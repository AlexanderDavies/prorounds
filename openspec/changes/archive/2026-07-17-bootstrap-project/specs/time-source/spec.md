## ADDED Requirements

### Requirement: TimeSource seam

The system SHALL define a `TimeSource` protocol that exposes the current monotonic instant (and the ability to await/schedule against it) as the single source of time for timing-sensitive code. Timing consumers SHALL depend on `TimeSource` by constructor injection, never on wall-clock or `Date()` directly.

#### Scenario: Consumers receive time only through the seam

- **WHEN** a timing-sensitive type needs the current instant
- **THEN** it reads it from an injected `TimeSource` rather than calling a global clock

### Requirement: Real monotonic implementation

The system SHALL provide a production `TimeSource` backed by a monotonic clock (`ContinuousClock`) whose instants never move backward and are unaffected by wall-clock changes.

#### Scenario: Instants are monotonic

- **WHEN** the real `TimeSource` is queried twice in succession
- **THEN** the second instant is greater than or equal to the first

### Requirement: Deterministic fake for tests

The system SHALL provide a `FakeTimeSource` whose instant is manually advanced by the test, so timing behavior can be verified deterministically without real elapsed time.

#### Scenario: Advancing the fake moves time forward by exactly the requested amount

- **WHEN** a test advances the `FakeTimeSource` by a given duration
- **THEN** the reported instant increases by exactly that duration and any work scheduled at or before the new instant becomes due

#### Scenario: The fake never advances on its own

- **WHEN** a test reads the `FakeTimeSource` without advancing it
- **THEN** the reported instant is unchanged from the previous read

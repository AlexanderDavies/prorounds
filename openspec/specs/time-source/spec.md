# time-source Specification

## Purpose
TBD - created by archiving change bootstrap-project. Update Purpose after archive.
## Requirements
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

### Requirement: Display-update tick stream

The `TimeSource` seam SHALL provide a `ticks(interval:)` stream of monotonic instants (~10–20 Hz) that a consumer can drive smooth display updates from, without polling a global clock. The production source SHALL emit ticks on a repeating timer; the `FakeTimeSource` SHALL let a test emit ticks by hand so an entire workout is driven deterministically. This is additive — existing `now` / `sleep(until:)` behaviour is unchanged.

#### Scenario: The fake emits ticks on demand

- **WHEN** a test requests a tick stream from `FakeTimeSource` and then advances/emits a tick
- **THEN** the stream yields the current monotonic instant, and yields nothing on its own until the test emits again

#### Scenario: The real source ticks at roughly the requested interval

- **WHEN** the production `TimeSource` produces a `ticks(interval:)` stream
- **THEN** it yields monotonic instants spaced by approximately the requested interval while observed


## ADDED Requirements

### Requirement: Display-update tick stream

The `TimeSource` seam SHALL provide a `ticks(interval:)` stream of monotonic instants (~10–20 Hz) that a consumer can drive smooth display updates from, without polling a global clock. The production source SHALL emit ticks on a repeating timer; the `FakeTimeSource` SHALL let a test emit ticks by hand so an entire workout is driven deterministically. This is additive — existing `now` / `sleep(until:)` behaviour is unchanged.

#### Scenario: The fake emits ticks on demand

- **WHEN** a test requests a tick stream from `FakeTimeSource` and then advances/emits a tick
- **THEN** the stream yields the current monotonic instant, and yields nothing on its own until the test emits again

#### Scenario: The real source ticks at roughly the requested interval

- **WHEN** the production `TimeSource` produces a `ticks(interval:)` stream
- **THEN** it yields monotonic instants spaced by approximately the requested interval while observed

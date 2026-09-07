# entitlement-seam Specification

## Purpose
Defines the boundary a future paywall plugs into, and the two limits it must always respect.

There is no paywall today and coaching ships unlocked. The seam exists so that changing that is an
edit to the composition root rather than a refactor across features — and, more importantly, so the
limits are structural rather than remembered. The entitlement decides exactly one thing, whether the
coaching cue stream is scheduled, and it is read synchronously from local state so there is no
suspension point a round could ever wait on. A paywall able to stall or corrupt a workout would
violate the product's first invariant, so the shape of the protocol is what prevents it.

## Requirements
### Requirement: Entitlement access is read through an injected seam
The system SHALL expose coaching entitlement through a constructor-injected protocol rather than a
concrete purchase API, so a future paywall is a composition-root change rather than a refactor. In
v1 the shipped implementation SHALL report coaching as unlocked, and no paywall UI SHALL be built.

#### Scenario: v1 reports coaching unlocked
- **WHEN** the app asks whether coaching is entitled
- **THEN** the shipped store SHALL answer yes, and no purchase prompt SHALL be shown

#### Scenario: A locked store can be substituted in tests
- **WHEN** a test injects a store reporting coaching as locked
- **THEN** the app SHALL behave as the locked path requires without any change to production code

#### Scenario: No purchase framework is linked in v1
- **WHEN** the entitlement seam is built
- **THEN** it SHALL NOT depend on StoreKit or any network call, keeping the local-first invariant

### Requirement: The entitlement gates only cue scheduling
The entitlement SHALL decide exactly one thing: whether the coaching cue stream is scheduled. It
SHALL NOT influence any other behaviour.

#### Scenario: A locked workout is otherwise identical
- **WHEN** a coached configuration runs with coaching not entitled
- **THEN** the workout SHALL run with its normal phases, round count, durations and audio cues, with
  only the coaching calls absent

#### Scenario: Configuration and settings are unaffected
- **WHEN** coaching is not entitled
- **THEN** a configuration SHALL still store its coaching level and the preferences SHALL still be
  readable and settable, so nothing is lost when entitlement is later granted

### Requirement: The entitlement must never reach the workout clock
The entitlement check SHALL NOT be reachable from the timer engine, and SHALL NOT be able to stall,
delay, or fail a round. A paywall that could corrupt a workout would violate the product's top
invariant.

#### Scenario: The timer engine has no entitlement dependency
- **WHEN** the timer engine is constructed
- **THEN** it SHALL take no entitlement store, and SHALL expose no way to consult one

#### Scenario: An entitlement check cannot block the clock
- **WHEN** the entitlement is consulted
- **THEN** the answer SHALL be returned synchronously from local state, with no I/O, no network, and
  no suspension point that a round could wait on


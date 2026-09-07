## ADDED Requirements

### Requirement: A coached round's calls are planned once, before the round runs
The system SHALL produce a round's coaching cues as a plan of offsets from the round start, computed
from the configuration's identity, the round index and the round length, before the round begins.
The plan SHALL be a pure function of those inputs.

#### Scenario: The plan is deterministic
- **WHEN** the same configuration, round index and round length are planned twice
- **THEN** the same cues at the same offsets SHALL be produced

#### Scenario: An uncoached configuration plans nothing
- **WHEN** a configuration has no coaching level
- **THEN** the plan SHALL be empty and the workout SHALL run exactly as it does today

#### Scenario: A workout type without a script plans nothing
- **WHEN** a configuration somehow carries coaching for a workout type with no script
- **THEN** the plan SHALL be empty rather than fail, since validation already prevents this being
  saved and a stored record must never crash a workout

### Requirement: The entitlement gates only the plan
When coaching is not entitled, the plan SHALL be empty. The entitlement SHALL NOT affect phases,
round count, durations, the bell, or any other cue.

#### Scenario: A locked workout is otherwise identical
- **WHEN** a coached configuration runs without entitlement
- **THEN** it SHALL emit exactly the cues an uncoached configuration would, at the same instants

#### Scenario: The entitlement is read outside the clock
- **WHEN** the plan is built
- **THEN** the entitlement SHALL be consulted synchronously before the round starts, and never from
  within the timing path

### Requirement: Calls resolve to clips through the stored naming convention
Each planned call SHALL resolve to the clip for the user's current naming convention, and a call
whose clip is missing SHALL be dropped from the plan rather than played as silence or crashed on.

#### Scenario: The convention selects the clip
- **WHEN** the naming convention is names and a forked phrase is planned
- **THEN** the clip from the names folder SHALL be used, and under numbers the numbers clip

#### Scenario: A shared phrase ignores the convention
- **WHEN** a shared phrase is planned under either convention
- **THEN** the same clip SHALL be used

#### Scenario: A missing clip is dropped, not fatal
- **WHEN** a planned phrase has no clip in the bundle
- **THEN** that call SHALL be omitted from the plan and the round SHALL run normally

### Requirement: Coaching never alters the shape of the workout
Coaching SHALL NOT move a phase boundary, change a round count, alter a duration, or delay the bell.

#### Scenario: Phase sequence is unchanged by coaching
- **WHEN** a coached and an uncoached configuration with identical timing are run against the same
  fake clock
- **THEN** every phase transition and every non-coaching cue SHALL occur at the same instant in both

#### Scenario: Coaching cues stop at the round boundary
- **WHEN** a round ends
- **THEN** no coaching cue from that round SHALL fire afterwards, in that round's rest or the next
  round

#### Scenario: Rest and prep are silent
- **WHEN** the workout is preparing or resting
- **THEN** no coaching cue SHALL fire, because v1 authors no rest or prep coaching

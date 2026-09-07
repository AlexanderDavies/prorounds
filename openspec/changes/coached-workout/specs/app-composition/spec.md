## ADDED Requirements

### Requirement: The composition root builds the coaching cue planner
The composition root SHALL construct the planner from the coaching catalog, the settings store and
the entitlement store, and inject it into the workout runtime. No feature SHALL construct one itself.

#### Scenario: The planner is built once and injected
- **WHEN** the object graph is built
- **THEN** one planner SHALL be constructed and passed to the runtime that needs it

#### Scenario: A catalog that fails to load degrades to no coaching
- **WHEN** the coaching catalog cannot be loaded at launch
- **THEN** the app SHALL start with coaching unavailable rather than fail to launch, because a
  content problem must never cost the user their timer

#### Scenario: The timer module still cannot reach coaching
- **WHEN** the object graph is built
- **THEN** the timer module SHALL still have no dependency on the coaching module, the planner
  reaching it only through the injected seam

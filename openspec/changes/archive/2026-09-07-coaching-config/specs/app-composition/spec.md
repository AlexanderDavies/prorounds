## ADDED Requirements

### Requirement: The composition root owns the entitlement store
The single composition root SHALL construct the entitlement store and inject it, consistent with
every other dependency. No feature SHALL construct one itself or reach a global.

#### Scenario: The entitlement store is built once and injected
- **WHEN** the object graph is built
- **THEN** exactly one entitlement store SHALL be constructed and passed to the types that need it

#### Scenario: Swapping the implementation is a composition-root change
- **WHEN** the entitlement implementation is replaced
- **THEN** only the composition root SHALL change, with no edit to any feature or data type

### Requirement: The app links the coaching module
The app target SHALL link `ProRoundsFoundationCoaching`, so the catalog and scheduler are reachable
from the running app rather than test-only.

#### Scenario: The coaching catalog loads in the app
- **WHEN** the app runs
- **THEN** the coaching catalog and both scripts SHALL load from the module bundle without error

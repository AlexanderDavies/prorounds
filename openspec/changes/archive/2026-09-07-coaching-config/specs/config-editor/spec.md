## ADDED Requirements

### Requirement: A Coaching section appears only where coaching is available
The editor SHALL offer a Coaching section for the workout types that have an authored script, and
SHALL omit it entirely for the others rather than showing a disabled control.

#### Scenario: The section is offered for a scripted type
- **WHEN** the workout type is Shadow Boxing or Heavy Bag
- **THEN** the editor SHALL show a Coaching section offering off or beginner

#### Scenario: The section is absent for an unscripted type
- **WHEN** the workout type is Skipping, Speed Ball or Sparring
- **THEN** no Coaching section SHALL be shown

#### Scenario: Switching to an unscripted type clears coaching
- **WHEN** a configuration with coaching enabled is changed to an unscripted workout type
- **THEN** its coaching level SHALL be cleared, so an invalid combination cannot be saved

### Requirement: Coaching is saved with the configuration
The chosen coaching level SHALL be persisted with the rest of the configuration, through the same
validate-then-save path.

#### Scenario: Editing coaching persists
- **WHEN** coaching is set to beginner and the configuration is saved
- **THEN** reopening that configuration SHALL show beginner

#### Scenario: An invalid coaching combination blocks the save
- **WHEN** a save is attempted with coaching set for an unscripted workout type
- **THEN** the save SHALL be blocked and the validation failure surfaced, consistent with the
  existing validate-before-persist behaviour

# config-editor Specification

## Purpose
TBD - created by archiving change config-feature. Update Purpose after archive.
## Requirements
### Requirement: Editable fields in spec order

The editor SHALL expose, in this order, the workout type (the five types in spec order) and value fields for number of rounds, round time, rest time, prep time, and round-end warning lead — plus an optional custom name. Each SHALL be editable within sensible bounds.

#### Scenario: Fields present in the specified order

- **WHEN** the editor is shown
- **THEN** it presents workout type, rounds, round time, rest time, prep time, and warning lead, in that order

### Requirement: Live total and auto-name preview

The editor SHALL show a live total-workout-time, recomputed from the current field values via the single-source calculator as the user edits. The name SHALL be a **single editable field** with an edit (pencil) affordance whose **placeholder is the live auto-generated name** while the custom name is blank — so a blank field reads as the auto-name, typing sets the custom name, and clearing it reverts to the auto-name. There SHALL NOT be a separate read-only name-preview row.

#### Scenario: Total updates as fields change

- **WHEN** the user changes the number of rounds
- **THEN** the displayed total time updates to match `round×N + rest×(N−1)` (prep excluded)

#### Scenario: Auto-name previews when the name is blank

- **WHEN** the name field is blank
- **THEN** the field shows the auto-generated name (for the current type, rounds, round, and rest) as its placeholder

#### Scenario: Editing the name sets the custom name; clearing reverts to the auto-name

- **WHEN** the user types into the name field
- **THEN** the typed text is used as the custom name; and when the field is cleared, the effective name reverts to the auto-generated name

### Requirement: Save validates before persisting

Save SHALL validate the configuration; when invalid it SHALL surface the specific problems and SHALL NOT persist; when valid it SHALL persist through the repository (insert or update) and dismiss the editor.

#### Scenario: Invalid input is blocked with feedback

- **WHEN** the user tries to save a configuration whose warning lead is not shorter than the round
- **THEN** the editor shows the validation problem and nothing is saved

#### Scenario: Valid input is persisted

- **WHEN** the user saves a valid configuration
- **THEN** it is stored through the repository and the editor dismisses

### Requirement: Delete when editing, cancel discards

When editing an existing configuration the editor SHALL offer a destructive Delete; Cancel SHALL discard any edits without persisting.

#### Scenario: Cancel discards edits

- **WHEN** the user changes fields and then cancels
- **THEN** the configuration in the repository is unchanged

#### Scenario: Delete removes an existing configuration

- **WHEN** the user deletes while editing an existing configuration
- **THEN** it is removed through the repository and the editor dismisses

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


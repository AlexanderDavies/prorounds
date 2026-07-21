## ADDED Requirements

### Requirement: Editable fields in spec order

The editor SHALL expose, in this order, the workout type (the five types in spec order) and value fields for number of rounds, round time, rest time, prep time, and round-end warning lead — plus an optional custom name. Each SHALL be editable within sensible bounds.

#### Scenario: Fields present in the specified order

- **WHEN** the editor is shown
- **THEN** it presents workout type, rounds, round time, rest time, prep time, and warning lead, in that order

### Requirement: Live total and auto-name preview

The editor SHALL show a live total-workout-time and, when the name is blank, the auto-generated name — both recomputed from the current field values via the single-source calculators as the user edits.

#### Scenario: Total updates as fields change

- **WHEN** the user changes the number of rounds
- **THEN** the displayed total time updates to match `prep + round×N + rest×(N−1)`

#### Scenario: Auto-name previews when the name is blank

- **WHEN** the name field is blank
- **THEN** the previewed name is the auto-generated name for the current type, rounds, round, and rest

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

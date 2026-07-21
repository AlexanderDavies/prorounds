## MODIFIED Requirements

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

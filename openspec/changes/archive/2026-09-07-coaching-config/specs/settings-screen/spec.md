## ADDED Requirements

### Requirement: Coaching preferences are settable from Settings
The Settings screen SHALL offer the naming convention and the minimal-screen preference, writing
both through the settings store.

#### Scenario: The convention can be changed
- **WHEN** the naming convention row is set to names
- **THEN** the store SHALL report names, and reopening Settings SHALL show names selected

#### Scenario: The minimal screen can be toggled
- **WHEN** the minimal-screen row is toggled
- **THEN** the store SHALL report the new value and it SHALL survive relaunch

#### Scenario: The convention is explained in the user's terms
- **WHEN** the naming convention is offered
- **THEN** each option SHALL be shown with an example of what the coach says, so the choice is
  legible to someone who does not yet know the numbering

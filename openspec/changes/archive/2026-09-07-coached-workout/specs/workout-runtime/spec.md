## ADDED Requirements

### Requirement: The idle workout screen offers a coaching shortcut
When a workout is idle and its type supports coaching, the screen SHALL offer a control showing the
current coaching level and allowing it to be changed, editing the same stored value the configuration
editor does.

#### Scenario: The control shows the current level
- **WHEN** an idle coached workout is shown
- **THEN** the control SHALL name the current level, or off when there is none

#### Scenario: Changing it persists to the same value
- **WHEN** the level is changed from the workout screen
- **THEN** the configuration SHALL be updated and the configuration list SHALL reflect it, with no
  second stored value

#### Scenario: The control is absent where coaching is unavailable
- **WHEN** the workout type has no coach script
- **THEN** no coaching control SHALL be offered

#### Scenario: The control is unavailable once running
- **WHEN** the workout is running
- **THEN** the coaching control SHALL NOT be offered, because changing the level mid-workout would
  change a round's plan after it began

### Requirement: The coaching sheet mirrors the naming convention
The sheet opened from the coaching control SHALL also offer the naming convention, writing the same
stored preference the Settings screen does.

#### Scenario: Setting the convention here is the same setting
- **WHEN** the convention is changed from the coaching sheet
- **THEN** the Settings screen SHALL show the new value, and vice versa

#### Scenario: The convention shows what the coach says
- **WHEN** the convention is offered
- **THEN** each option SHALL carry an example of the coach's words

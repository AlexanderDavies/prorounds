# settings-screen Specification

## Purpose
TBD - created by archiving change settings. Update Purpose after archive.
## Requirements
### Requirement: Warning sound selection with preview

The Settings screen SHALL present the three warning sounds (wooden clap, electronic horn, buzzer) as selectable rows; selecting one SHALL persist it through the store and **play a preview** of that sound.

#### Scenario: Selecting a warning sound persists and previews it

- **WHEN** the user selects the buzzer
- **THEN** the buzzer is saved as the warning sound and a preview of the buzzer plays

### Requirement: Timer display direction

The screen SHALL let the user choose count down or count up, persisted through the store.

#### Scenario: Choosing count up persists it

- **WHEN** the user selects count up
- **THEN** the count direction is saved as count up

### Requirement: Appearance control

The screen SHALL offer Light / Dark / System (system is the default), persisted through the store.

#### Scenario: Choosing dark persists it

- **WHEN** the user selects Dark
- **THEN** the appearance preference is saved as dark

### Requirement: Appearance is applied app-wide

The chosen appearance SHALL drive the app's color scheme — Light forces light, Dark forces dark, System follows the device — and SHALL update immediately when changed.

#### Scenario: Changing the appearance re-themes the app

- **WHEN** the user switches the appearance to Dark
- **THEN** the app renders in dark immediately, and System returns it to following the device

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


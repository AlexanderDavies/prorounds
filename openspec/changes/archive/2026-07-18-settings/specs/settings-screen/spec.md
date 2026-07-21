## ADDED Requirements

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

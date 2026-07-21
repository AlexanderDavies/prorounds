# app-shell Specification

## Purpose
TBD - created by archiving change bootstrap-project. Update Purpose after archive.
## Requirements
### Requirement: Three-tab root navigation

The app SHALL launch into a root `TabView` presenting exactly three tabs — Timer, Performance, and Settings — with Timer selected by default. The **Timer tab's root SHALL be the Configurations list** (inside a `NavigationStack`), the **Performance tab SHALL show the performance chart**, and the **Settings tab SHALL show the settings screen**.

#### Scenario: App launches to the Timer tab

- **WHEN** the app is launched
- **THEN** a three-tab bar (Timer, Performance, Settings) is shown with the Timer tab selected and the Configurations list (or its empty state) displayed

#### Scenario: Tabs are switchable

- **WHEN** the user taps the Performance or Settings tab
- **THEN** the corresponding tab's content is displayed — the performance chart for Performance, the settings screen for Settings — and its tab item appears selected

### Requirement: Tab items follow the design's iconography

The tab items SHALL use the SF Symbols named in the design (`timer`, `chart.line.uptrend.xyaxis`, `gearshape`) with the labels Timer, Performance, and Settings.

#### Scenario: Correct symbols and labels render

- **WHEN** the tab bar is displayed
- **THEN** each tab shows its designated SF Symbol and label

### Requirement: App shell renders in light and dark appearance

The app shell SHALL render correctly in both light and dark system appearances.

#### Scenario: Both appearances render without layout breakage

- **WHEN** the app runs under light appearance and again under dark appearance
- **THEN** the tab bar and placeholder content render legibly in each

### Requirement: Switching tabs returns the Timer tab to its list

Switching away from the Timer tab and back SHALL land on the Timer tab's root — the Configurations list — not a previously-opened workout screen. Opening a workout, leaving to another tab, and re-selecting Timer SHALL therefore show the list (any in-progress workout is abandoned and its engine reset, per `workout-runtime`), so the user always returns home rather than to a stale, half-torn-down running screen.

#### Scenario: Returning to the Timer tab shows the configuration list

- **WHEN** the user opens a workout, switches to the Settings (or Performance) tab, and then re-selects the Timer tab
- **THEN** the Timer tab shows the Configurations list (home), not the workout screen


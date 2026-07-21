## ADDED Requirements

### Requirement: Switching tabs returns the Timer tab to its list

Switching away from the Timer tab and back SHALL land on the Timer tab's root — the Configurations list — not a previously-opened workout screen. Opening a workout, leaving to another tab, and re-selecting Timer SHALL therefore show the list (any in-progress workout is abandoned and its engine reset, per `workout-runtime`), so the user always returns home rather than to a stale, half-torn-down running screen.

#### Scenario: Returning to the Timer tab shows the configuration list

- **WHEN** the user opens a workout, switches to the Settings (or Performance) tab, and then re-selects the Timer tab
- **THEN** the Timer tab shows the Configurations list (home), not the workout screen

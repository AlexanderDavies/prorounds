## ADDED Requirements

### Requirement: Multi-line chart of training volume over time

The Performance screen SHALL render the active-minutes series with Swift Charts as a line per workout type in the categorical palette (DESIGN §7.5) plus a heavier Total line, with time on the X axis and active minutes on the Y axis. It SHALL render from injected, pre-shaped series — no live fetch in the view (guide §13.3) — so it snapshots deterministically.

#### Scenario: A line per type plus a total renders

- **WHEN** the screen is shown with series for two workout types
- **THEN** it draws a line per type in its palette color and a heavier total line

### Requirement: Range control

The screen SHALL provide a Week / Month / All segmented control that changes the range the metrics use, updating the chart and summary tiles.

#### Scenario: Changing the range updates the chart

- **WHEN** the user selects a different range
- **THEN** the chart and summary tiles update to that range's data

### Requirement: Summary tiles

The screen SHALL show summary tiles above the chart — the period's active minutes, session count, and rounds completed.

#### Scenario: Tiles show the period figures

- **WHEN** the screen is shown for a range
- **THEN** the tiles display that range's active minutes, session count, and rounds

### Requirement: Tappable legend isolates a series

The legend SHALL be tappable to toggle a series' visibility, so the user can isolate one type or hide the total.

#### Scenario: Toggling a legend entry hides its line

- **WHEN** the user taps a legend entry for a visible series
- **THEN** that series' line is hidden and the entry appears de-emphasised, and tapping again restores it

### Requirement: Empty state

When there are no sessions, the screen SHALL show an empty state inviting the user to complete a workout, instead of an empty chart.

#### Scenario: Empty state when there are no sessions

- **WHEN** the screen is shown with no sessions
- **THEN** an empty state ("complete a workout to see your trends") is shown rather than a blank chart

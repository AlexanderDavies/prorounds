# duration-formatting Specification

## Purpose
TBD - created by archiving change bootstrap-project. Update Purpose after archive.
## Requirements
### Requirement: Single-source total-workout-duration calculation

The system SHALL provide one calculator for a workout's total duration from a configuration, computed as `(round × N) + (rest × (N − 1))` — **prep is excluded** (it is a lead-in, not workout time), and there is no rest after the final round. This calculation SHALL have exactly one implementation reused everywhere a total is shown.

#### Scenario: Total excludes rest after the final round

- **WHEN** the total is computed for 12 rounds of 3:00 with 1:00 rest and 0:10 prep
- **THEN** the result is 12×round + 11×rest = 36:00 + 11:00 = 47:00 (prep excluded, no rest after the final round)

#### Scenario: Single round has no rest

- **WHEN** the total is computed for 1 round of 2:00 with 0:30 rest and 0:00 prep
- **THEN** the result is 2:00 (no rest is added)

#### Scenario: Prep is not counted in the total

- **WHEN** the same rounds/rest are computed with a 0:20 prep versus a 0:00 prep
- **THEN** the total is identical — prep does not change it

### Requirement: Auto-generated configuration name

The system SHALL provide one formatter that derives a default configuration name from the workout type, number of rounds, round duration, and rest period, in the design's format (e.g. "Heavy Bag · 12×3min / 1min rest").

#### Scenario: Name is derived from configuration fields

- **WHEN** the auto-name is generated for Heavy Bag, 12 rounds, 3:00 round, 1:00 rest
- **THEN** the result is "Heavy Bag · 12×3min / 1min rest"

#### Scenario: Auto-name is used only when no custom name is provided

- **WHEN** a configuration has a non-empty custom name
- **THEN** the custom name is used and the auto-name formatter is not applied

### Requirement: Duration formatting for display

The system SHALL provide time-formatting helpers that render durations as monospaced `m:ss` (or `h:mm:ss` when an hour or more) for the timer and metadata rows.

#### Scenario: Sub-hour duration formats as m:ss

- **WHEN** 83 seconds is formatted
- **THEN** the result is "1:23"

#### Scenario: Hour-or-more duration includes hours

- **WHEN** 3723 seconds is formatted
- **THEN** the result is "1:02:03"


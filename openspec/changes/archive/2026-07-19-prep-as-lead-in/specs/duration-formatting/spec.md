## MODIFIED Requirements

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

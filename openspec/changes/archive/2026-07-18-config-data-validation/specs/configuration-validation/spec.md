## ADDED Requirements

### Requirement: Single configuration validator with the boundary rules

The system SHALL provide one `ConfigurationValidator` that checks a configuration against the guide §11 rules — `roundCount ≥ 1`, `roundDuration > 0`, `restDuration ≥ 0`, `prepDuration ≥ 0`, and `0 ≤ warningLead < roundDuration` — and reports each violation as a typed error. It is the single home for these rules; the engine assumes valid input and does not re-validate.

#### Scenario: A well-formed configuration is valid

- **WHEN** a configuration with 12 rounds, 3:00 round, 1:00 rest, 0:10 prep, and 0:10 warning lead is validated
- **THEN** validation reports no errors

#### Scenario: A zero-round configuration is rejected

- **WHEN** a configuration with 0 rounds is validated
- **THEN** validation reports a round-count violation

#### Scenario: A non-positive round duration is rejected

- **WHEN** a configuration whose round duration is zero is validated
- **THEN** validation reports a round-duration violation

### Requirement: Warning lead must be shorter than the round

The validator SHALL reject a warning lead that is negative or greater than or equal to the round duration (a warning cannot equal or exceed the round it precedes). A zero warning lead SHALL be valid (it means "no warning").

#### Scenario: A warning lead at or beyond the round length is rejected

- **WHEN** a configuration with a 3:00 round and a 3:00 warning lead is validated
- **THEN** validation reports a warning-lead violation

#### Scenario: A zero warning lead is accepted

- **WHEN** a configuration with a 0 warning lead is validated
- **THEN** no warning-lead violation is reported

### Requirement: All violations are reported together

When a configuration breaks several rules, the validator SHALL report every violation, not just the first, so an editor can surface them all at once.

#### Scenario: Multiple violations are all reported

- **WHEN** a configuration with 0 rounds and a zero round duration is validated
- **THEN** validation reports both the round-count and the round-duration violations

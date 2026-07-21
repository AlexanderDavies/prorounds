# session-model Specification

## Purpose
TBD - created by archiving change session-history. Update Purpose after archive.
## Requirements
### Requirement: A session records a completed workout

The system SHALL define a `Session` value type (`Sendable`, `Identifiable`) capturing a completed workout: its date, workout type, the configuration used (name, rounds, round/rest/prep durations), the number of rounds completed, and the total duration — where **total is the workout time (rounds + rest), excluding prep**.

#### Scenario: A session captures the workout's key details

- **WHEN** a session is created for a completed 12×3:00 Heavy Bag workout named "Heavy Bag Blast"
- **THEN** it records the date, `.heavyBag`, the name, 12 rounds completed, and the durations, with a total of rounds + rest (prep excluded)

### Requirement: Active duration is the sum of round time

A session SHALL expose an **active duration** equal to the sum of its completed rounds' round time (rest and prep excluded) — the "time under work" the performance chart measures (DESIGN §7.4).

#### Scenario: Active duration excludes rest and prep

- **WHEN** the active duration is read for a completed 12×3:00 workout with 1:00 rest and 0:10 prep
- **THEN** it is 36:00 (12 × 3:00), not the total workout time


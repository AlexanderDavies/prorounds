## MODIFIED Requirements

### Requirement: A session records a completed workout

The system SHALL define a `Session` value type (`Sendable`, `Identifiable`) capturing a completed workout: its date, workout type, the configuration used (name, rounds, round/rest/prep durations), the number of rounds completed, and the total duration — where **total is the workout time (rounds + rest), excluding prep**.

#### Scenario: A session captures the workout's key details

- **WHEN** a session is created for a completed 12×3:00 Heavy Bag workout named "Heavy Bag Blast"
- **THEN** it records the date, `.heavyBag`, the name, 12 rounds completed, and the durations, with a total of rounds + rest (prep excluded)

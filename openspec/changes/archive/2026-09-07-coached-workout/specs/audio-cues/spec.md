## ADDED Requirements

### Requirement: A cue can name a spoken clip by location
The cue type SHALL carry a case for a spoken clip identified by its file location, so a coaching call
is expressible as an ordinary cue without the audio layer depending on the coaching module.

#### Scenario: A spoken cue carries its clip
- **WHEN** a spoken cue is constructed for a clip
- **THEN** it SHALL carry that clip's location and compare equal only to a cue for the same clip

#### Scenario: Spoken cues do not disturb the existing cues
- **WHEN** the existing round-start, warning, round-end, rest-start and complete cues are used
- **THEN** their behaviour and equality SHALL be unchanged

## ADDED Requirements

### Requirement: The player plays a spoken clip from its location
The player SHALL play a spoken cue's clip, and SHALL keep its existing behaviour for bundled sounds,
background audio and interruptions.

#### Scenario: A spoken clip plays
- **WHEN** a spoken cue is played
- **THEN** the clip at its location SHALL be played

#### Scenario: A missing or unreadable clip is survivable
- **WHEN** a spoken cue names a clip that cannot be read
- **THEN** the player SHALL continue without crashing, and the workout SHALL be unaffected

#### Scenario: Spoken clips follow the session's interruption behaviour
- **WHEN** an interruption occurs while a spoken clip is playing
- **THEN** the existing interruption handling SHALL apply, and the workout SHALL NOT be corrupted

#### Scenario: A call does not clip the bell
- **WHEN** a spoken clip is still playing as a phase-boundary cue fires
- **THEN** the boundary cue SHALL still be played, since the bell is the more important sound

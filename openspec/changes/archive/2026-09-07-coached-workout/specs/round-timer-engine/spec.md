## ADDED Requirements

### Requirement: The engine emits injected per-round cues at their offsets
The engine SHALL accept, per round, a plan of cues with offsets from that round's start, and SHALL
emit each as its offset is crossed, using the same monotonic-deadline arithmetic as its own cues. It
SHALL treat the plan as opaque data and SHALL NOT depend on what the cues mean.

#### Scenario: A planned cue fires at its offset
- **WHEN** a round is given a cue at a 30-second offset and the fake clock advances past it
- **THEN** that cue SHALL be emitted once, at that instant

#### Scenario: Cues fire in offset order
- **WHEN** several cues are planned in one round
- **THEN** they SHALL be emitted in ascending offset order

#### Scenario: A tick that crosses several offsets fires all of them
- **WHEN** the clock jumps past several planned offsets at once
- **THEN** every crossed cue SHALL be emitted, in order, none skipped and none repeated

#### Scenario: No cue fires twice
- **WHEN** ticks continue after a planned cue has fired
- **THEN** it SHALL NOT fire again

#### Scenario: An empty plan changes nothing
- **WHEN** a round has no planned cues
- **THEN** the engine SHALL behave exactly as it does without the feature

### Requirement: Planned cues never affect timing
Planned cues SHALL NOT influence phase transitions, deadlines, the round count, or the workout total.

#### Scenario: Transitions are unaffected
- **WHEN** the same workout is run with and without a plan against the same fake clock
- **THEN** every phase transition SHALL occur at an identical instant in both runs

#### Scenario: A plan extending past the round is truncated
- **WHEN** a plan contains an offset beyond the round's length
- **THEN** that cue SHALL NOT fire and the round SHALL end on time

### Requirement: Planned cues respect pause, resume and reset
Planned cues SHALL follow the same rules as the engine's own cues under transport control.

#### Scenario: Pausing suppresses pending cues
- **WHEN** the workout is paused
- **THEN** no planned cue SHALL fire while paused

#### Scenario: Resuming preserves the remaining plan
- **WHEN** the workout resumes after a pause
- **THEN** cues not yet reached SHALL still fire at their offsets relative to the round, with the
  pause excluded — the same deadline recomputation the engine already performs

#### Scenario: Reset clears the plan
- **WHEN** the workout is reset
- **THEN** no cue from the abandoned round SHALL fire afterwards

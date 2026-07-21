## ADDED Requirements

### Requirement: Interruptions pause and resume cleanly

When an audio-session interruption begins (e.g. a phone call), the running workout SHALL pause; when it ends, the workout SHALL be resumable in the correct phase with the correct remaining time (the deadline engine recomputes on resume). The workout SHALL never be silently corrupted (invariant §0.6.4).

#### Scenario: A call pauses the workout, and it resumes correctly

- **WHEN** an interruption begins mid-round and later ends
- **THEN** the workout pauses at that point and, on resume, continues the same round with the remaining time intact

### Requirement: Route changes are handled

An audio route change (e.g. headphones unplugged) SHALL be handled gracefully — it SHALL NOT crash, freeze the timer, or leave the audio in a broken state.

#### Scenario: Unplugging headphones does not break the workout

- **WHEN** the audio route changes during a workout
- **THEN** the workout continues (or pauses per policy) without crashing or corrupting the timer

### Requirement: Controls always reflect the true engine state

After any interruption, the transport controls SHALL reflect the engine's actual running/paused state — never a stale or contradictory affordance.

#### Scenario: Controls match the engine after an interruption

- **WHEN** an interruption pauses the workout
- **THEN** the controls show the paused (resume) state, matching the engine

# audio-playback Specification

## Purpose
TBD - created by archiving change workout-runtime. Update Purpose after archive.
## Requirements
### Requirement: Concrete cue player preloads and plays bundled sounds

The system SHALL provide an `AVFoundation`-backed `AudioCuePlayer` that preloads its bundled sound assets on `prepare()` (so the first cue is on time) and plays a sound for each `AudioCue` with low latency. It SHALL import audio frameworks only inside this player — the engine and views use the protocol.

#### Scenario: Preparing preloads the sounds

- **WHEN** `prepare()` is called
- **THEN** the bundled sounds are loaded so the first `play(_:)` is not delayed by disk I/O

### Requirement: Each cue maps to a sound

The player SHALL map cues to sounds deterministically: round start/end and rest start use the bell, the round-end warning uses the selected `WarningSound` (wooden clap / electronic horn / buzzer), and workout complete uses a distinct completion sound. This mapping SHALL be a pure function, unit-tested independently of audio hardware.

#### Scenario: Warning cue selects the configured warning sound

- **WHEN** the cue→sound mapping resolves a round-end warning carrying the buzzer
- **THEN** it selects the buzzer asset (not the bell)

#### Scenario: Bell and complete map to their sounds

- **WHEN** the mapping resolves round start, round end, and workout complete
- **THEN** round start and round end resolve to the bell and workout complete resolves to the completion sound

### Requirement: Playback session ducks other audio

The player SHALL configure an `AVAudioSession` for `.playback` with option `.duckOthers`, so cues sound even with the ringer silent and the user's music dips briefly for a cue rather than stopping.

#### Scenario: Cues sound with the ringer silent and duck music

- **WHEN** a workout plays a cue while the device is on silent and music is playing
- **THEN** the cue is audible and the music volume dips for the cue, then returns

### Requirement: Cues keep firing in the background

The app SHALL declare the `audio` background mode and keep the audio session active while a workout runs, so bell and warning cues fire even with the screen locked or the app backgrounded.

#### Scenario: A cue fires with the screen locked

- **WHEN** a workout is running and the screen locks
- **THEN** the round/warning cues continue to fire at their scheduled instants


# audio-cues Specification

## Purpose
TBD - created by archiving change round-timer-engine. Update Purpose after archive.
## Requirements
### Requirement: Audio cue vocabulary

The system SHALL define an `AudioCue` type enumerating the moments the engine signals: round start, round-end warning (carrying the selected warning sound), round end, rest start, and workout complete. `AudioCue` SHALL be `Equatable`/`Sendable` so tests can assert exact cue sequences.

#### Scenario: Cue cases cover every signalled moment

- **WHEN** the `AudioCue` cases are enumerated
- **THEN** they include round start, round-end warning, round end, rest start, and workout complete

### Requirement: Warning sound options

The system SHALL define a `WarningSound` enumeration with the three options from the spec — wooden clap, electronic horn, and buzzer — as `CaseIterable`/`Codable`/`Sendable` so it can be selected in settings and persisted later.

#### Scenario: Three warning sounds are available

- **WHEN** the `WarningSound` cases are listed
- **THEN** they are wooden clap, electronic horn, and buzzer

### Requirement: AudioCuePlayer seam

The system SHALL define an `AudioCuePlayer` protocol with `prepare()` (preload) and `play(_:)` (emit a cue), `Sendable`, so the engine can emit cues without importing audio frameworks. A `SpyAudioCuePlayer` test double SHALL record played cues in order. The concrete `AVFoundation`-backed player is out of scope for this capability.

#### Scenario: The engine plays through the seam, not the hardware

- **WHEN** the engine signals a cue
- **THEN** it calls `play(_:)` on its injected `AudioCuePlayer`, and a spy records the cue in the order it was played

### Requirement: A cue can name a spoken clip by location
The cue type SHALL carry a case for a spoken clip identified by its file location, so a coaching call
is expressible as an ordinary cue without the audio layer depending on the coaching module.

#### Scenario: A spoken cue carries its clip
- **WHEN** a spoken cue is constructed for a clip
- **THEN** it SHALL carry that clip's location and compare equal only to a cue for the same clip

#### Scenario: Spoken cues do not disturb the existing cues
- **WHEN** the existing round-start, warning, round-end, rest-start and complete cues are used
- **THEN** their behaviour and equality SHALL be unchanged


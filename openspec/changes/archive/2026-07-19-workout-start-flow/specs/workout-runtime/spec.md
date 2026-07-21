## MODIFIED Requirements

### Requirement: Transport controls drive the engine

Play/pause and reset on the screen SHALL forward to the engine, and the controls SHALL reflect the true engine state. The screen SHALL open **idle** (not running): before the first start the primary control shows **Play** and starts the engine. While running it shows **Pause**; while paused it shows **Play** (resume). `reset()` SHALL return the screen to idle so Play is shown again. The primary control's intent is therefore: if the workout has not started, start it; otherwise toggle pause.

#### Scenario: Pause forwards to the engine and reflects state

- **WHEN** the user taps pause while running
- **THEN** the engine is paused and the control shows the play (resume) affordance

#### Scenario: The screen opens idle and the first tap starts the workout

- **WHEN** the running screen appears and the user has not yet tapped Play
- **THEN** the engine is not running and the primary control shows Play; tapping it starts the workout

#### Scenario: Reset returns the screen to idle

- **WHEN** a running or paused workout is reset
- **THEN** the screen returns to idle and the primary control shows Play again (from which it can be started)

### Requirement: Start a workout from a configuration

Tapping a configuration in the list SHALL open that configuration's workout on the running screen — with the engine wired to the real clock and the audio player — in a **ready (idle) state**. The workout SHALL NOT auto-start; it begins when the user taps Play.

#### Scenario: Tapping a configuration starts its workout

- **WHEN** the user taps a configuration card
- **THEN** the running screen opens for that configuration in a ready state, and the workout begins when the user taps Play

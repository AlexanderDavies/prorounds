# workout-runtime Specification

## Purpose
TBD - created by archiving change workout-runtime. Update Purpose after archive.
## Requirements
### Requirement: The running screen reflects the engine's snapshots

The workout screen SHALL render the engine's current `WorkoutSnapshot` via a `WorkoutDisplayModel` — the phase label, the current-phase time, the total remaining, and the ring progress — mapped outside the view. The view SHALL do no timer math or formatting.

#### Scenario: Snapshot drives the display

- **WHEN** the engine emits a snapshot for round 3 of 12 with 1:23 left
- **THEN** the screen shows the round-3-of-12 phase label, "1:23", and the ring filled to the phase progress

### Requirement: Count direction is a display choice

The displayed phase time SHALL show either the remaining time (count down) or the elapsed time (count up) per the injected `CountDirection`, resolved in the display mapping — the engine's sequencing SHALL NOT depend on it. The default is count down until settings wire it.

#### Scenario: Count up shows elapsed, count down shows remaining

- **WHEN** the same snapshot (elapsed 0:37, remaining 1:23 in the phase) is mapped for count up versus count down
- **THEN** count up shows "0:37" and count down shows "1:23"

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

### Requirement: Phase-tinted UI and finished summary

The screen SHALL tint by the current phase (prepare/round/rest colors) and, on completion, show a finished state (a "done" treatment and a one-line summary of rounds/total/type) with an action returning to the list.

#### Scenario: Finished state appears on completion

- **WHEN** the final round completes
- **THEN** the screen shows the finished treatment with a summary and a way back to the list

### Requirement: Keep the screen awake while running

While a workout is running the app SHALL keep the screen awake (an injected idle-timer seam), and restore normal idle behaviour when the workout finishes or the screen is left.

#### Scenario: Idle timer is disabled during a workout and restored after

- **WHEN** a workout starts and later finishes (or the screen is left)
- **THEN** the idle timer is disabled while running and re-enabled afterwards

### Requirement: Start a workout from a configuration

Tapping a configuration in the list SHALL open that configuration's workout on the running screen — with the engine wired to the real clock and the audio player — in a **ready (idle) state**. The workout SHALL NOT auto-start; it begins when the user taps Play.

#### Scenario: Tapping a configuration starts its workout

- **WHEN** the user taps a configuration card
- **THEN** the running screen opens for that configuration in a ready state, and the workout begins when the user taps Play

### Requirement: A completed workout is saved as a session

When a workout reaches the finished phase, the app SHALL build a `Session` from the configuration and completion and save it through the `SessionRepository`. Only a naturally-completed workout SHALL be saved — leaving or resetting mid-workout SHALL save nothing.

#### Scenario: Finishing a workout saves a session

- **WHEN** a workout runs to completion
- **THEN** a session for that configuration is persisted through the repository

#### Scenario: Resetting mid-workout saves nothing

- **WHEN** a running workout is reset or left before finishing
- **THEN** no session is saved

### Requirement: A failed session save is surfaced with retry

If saving the completed session fails, the app SHALL NOT silently drop it (§10.4) — the finished screen SHALL indicate the failure and offer a Retry that attempts the save again.

#### Scenario: A save failure offers a retry

- **WHEN** saving the completed session fails
- **THEN** the finished screen shows the failure and a Retry action, and retrying attempts the save again


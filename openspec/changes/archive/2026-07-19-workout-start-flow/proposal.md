## Why

Selecting a workout **auto-starts** the timer the moment the running screen appears — the user never
gets a "ready" beat, and (worse) after going to Settings and back the engine resets but the screen
still shows a Pause control over a stopped engine, with **no way to start it**. Separately, editing an
existing workout is only reachable via a **left-swipe** on the config card — undiscoverable; the user
couldn't find it. (From hands-on use — `changes.md` #5 and #6.)

## What Changes

- **The running screen opens idle, not running.** `onAppear` no longer starts the engine; it wires up
  observation and shows the ready state. The primary transport control shows **Play** (`play.fill`) and
  starts the workout on tap.
- **The transport control is start-aware.** Its intent is: **idle → Play (start)**, **running →
  Pause**, **paused → Play (resume)**. `reset()` returns the screen to idle, so Play shows again — which
  fixes the "stuck on Pause after Settings-and-back" dead end.
- **The engine snapshot exposes a run-state flag.** The engine already tracks `started`; the snapshot
  now carries it, so the display knows idle-vs-running without duplicating state, and the pre-start /
  post-reset snapshot reports not-started.
- **Editing is discoverable via a long-press context menu.** Each config card gains a standard iOS
  context menu with **Edit** and **Delete**; the existing swipe actions stay.

## Capabilities

### Modified Capabilities
- `round-timer-engine`: the snapshot carries a run-state (started) flag; the pre-start and post-reset
  snapshot report not-started.
- `workout-runtime`: the running screen opens idle and starts on Play; the transport control is
  start-aware (idle→start, running→pause, paused→resume) and reset returns to idle.
- `config-list`: editing an existing configuration is also reachable from a long-press context menu on
  the card (Edit/Delete), alongside the existing swipe-to-edit.

## Impact

- `WorkoutSnapshot` (+`started`), `RoundTimerEngine` (populate it), `WorkoutDisplayModel`
  (`isRunning`/idle derivation), `WorkoutViewModel` (no auto-start; start-aware `playPause`),
  `WorkoutView`/`TransportControls` wiring, `ConfigListView` (context menu).
- Update the workout view-model tests (onAppear no longer starts; Play starts; reset returns to idle)
  and the engine snapshot tests (run-state flag); re-record the workout snapshots to add an **idle**
  state. No change to sequencing, cues, timing, or persistence.

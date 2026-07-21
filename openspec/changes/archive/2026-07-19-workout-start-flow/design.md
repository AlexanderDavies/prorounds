## Context

The running screen auto-starts on appear and has no idle state, so (a) there's no "ready" beat and
(b) after Settings-and-back the engine is reset but the display still shows Pause over a stopped
engine with no way to start. Editing a workout is only reachable via a left-swipe — undiscoverable.

## Goals / Non-Goals

- **Goals:** an idle→Play start flow on the running screen; a start-aware transport control; reset
  returns to idle; a discoverable Edit affordance (long-press context menu).
- **Non-Goals:** no change to sequencing, cues, timing, persistence, or the count-direction display.
  No ready-screen toolbar Edit button (decided: context menu only). No audio pre-load seam (Play
  already prepares audio, and the 20s default prep gives ample lead before the first cue).

## Decisions

### Run-state lives on the snapshot (single source of truth)

The engine already tracks `started` internally. Rather than duplicate a "hasStarted" flag in the view
model, we surface `started` on `WorkoutSnapshot`. The display then derives idle-vs-running from the
snapshot, and — because `reset()` publishes an initial snapshot with `started == false` — the
Settings-and-back dead end is fixed for free (the reset snapshot naturally shows Play).

- `WorkoutSnapshot` gains `started: Bool`.
- `initialSnapshot(for:)` and the state after `reset()` → `started = false`.
- `beginTimeline` / all running snapshots → `started = true`; the finished snapshot → `started = true`
  (the workout ran), but `isFinished` takes display precedence.

### Display derivation

`WorkoutDisplayModel.isRunning = snapshot.started && !isPaused && !isFinished`.
`TransportControls` already maps `isRunning == false` → `play.fill` ("Start/Resume workout") and
`true` → `pause.fill`. So idle (`!started`) and paused both show Play; running shows Pause — no new
glyph needed in the design system. The model also exposes `isStarted` for the view model's start-aware
intent (or the view model reads `engine.snapshot.started`).

### Start-aware primary intent

`WorkoutViewModel.onAppear()` stops calling `engine.start()`; it refreshes `display` from
`engine.snapshot`, wires the snapshot + interruption observation, and disables the idle timer (the
screen is up). A new `playPause()` implements: `if engine.snapshot.started { engine.togglePause() }
else { engine.start() }`. `WorkoutView`'s `onPlayPause` calls `model.playPause()`.

### Edit discoverability — context menu

`ConfigCard` in `ConfigListView` gains a `.contextMenu` with **Edit** (opens the editor sheet for that
configuration) and **Delete** (destructive). The existing leading swipe-to-edit and trailing
swipe-to-delete stay.

## Risks / Trade-offs

- **Interruption before start:** `handleInterruptionBegan` already guards on `!isPaused && phase !=
  finished`; `engine.togglePause()` guards on `started`. An interruption while idle is a no-op — good.
- **AsyncStream re-subscription on re-appear:** onAppear now refreshes `display` from
  `engine.snapshot` synchronously, so the idle state shows immediately even if the buffered snapshot
  arrives a beat later.

## Migration Plan

Pure in-place behavioural change; no data or persistence migration. Update view-model + engine tests
and re-record the workout snapshots (new idle state) in the same change set.

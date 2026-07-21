## 1. Engine — run-state on the snapshot

- [x] 1.1 Failing engine test: `initialSnapshot` and the post-`reset()` snapshot report `started == false`; after `start()`/`beginTimeline` the snapshot reports `started == true` (spec: round-timer-engine)
- [x] 1.2 Add `started: Bool` to `WorkoutSnapshot`; populate it in `RoundTimerEngine` (initial/reset false, begin/running/finished true) — green

## 2. Display — idle vs running

- [x] 2.1 Failing `WorkoutDisplayModel` test: a not-started snapshot ⇒ `isRunning == false` (Play shown); a started+unpaused snapshot ⇒ `isRunning == true`; paused ⇒ `isRunning == false` (spec: workout-runtime)
- [x] 2.2 Derive `isRunning = started && !isPaused && !isFinished`; expose `isStarted` — green

## 3. View model — no auto-start, start-aware Play

- [x] 3.1 Update view-model tests: `onAppear` disables idle but does NOT start (display not running); a new `playPause()` starts from idle; after `reset()` the display is idle again (spec: workout-runtime)
- [x] 3.2 `onAppear` refreshes `display` from `engine.snapshot` and drops `engine.start()`; add `playPause()` = start-if-idle-else-togglePause; wire `WorkoutView.onPlayPause` → `playPause()` — green

## 4. Config list — context-menu Edit/Delete

- [x] 4.1 Add a `.contextMenu` (Edit + Delete) to the config card in `ConfigListView`, keeping the swipe actions (spec: config-list)

## 5. Verification

- [x] 5.1 `./scripts/test.sh` + `./scripts/coverage.sh` green; `./scripts/lint.sh` strict clean
- [x] 5.2 Re-record the workout snapshots to add the idle/ready state; review the ready screen shows Play
- [x] 5.3 `openspec validate workout-start-flow` clean; README unaffected (behaviour, not build)

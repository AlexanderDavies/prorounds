## 1. RootView — reset the Timer path on tab switch

- [x] 1.1 Add a `Tab` selection binding to the root `TabView` with `.tag(...)` per tab; clear `workoutPath` on `onChange(of: selectedTab)` (spec: app-shell)

## 2. XCUITest

- [x] 2.1 Update `test_startPauseResetWorkout` for the idle-first screen: tap card → Play, tap Play → Pause, pause → resume, reset
- [x] 2.2 Add `test_returningToTimerTabShowsTheList`: open a workout, go to Settings, return to Timer, assert the configuration list is shown (not the workout screen)

## 3. Verification

- [x] 3.1 `./scripts/test.sh` + `./scripts/lint.sh` green (package suite unaffected)
- [x] 3.2 Run the XCUITest flow (the `ProRounds` scheme) on the simulator — both tests green
- [x] 3.3 `openspec validate timer-tab-reset` clean; README unaffected

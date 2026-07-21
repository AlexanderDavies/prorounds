## 1. Shared types & engine snapshot stream

- [x] 1.1 Add `CountDirection` (countDown/countUp) to `ProRoundsFoundationUtilities` with a small test
- [x] 1.2 Add a `snapshots` `AsyncStream<WorkoutSnapshot>` to `RoundTimerEngine` (tick loop + initial value yield); test it emits the sequence a short workout produces (via `FakeTimeSource`)

## 2. Audio assets & concrete player (ProRoundsFoundationAudio)

- [x] 2.1 Add a committed `scripts/gen-audio.sh` (or Swift/Python) generating placeholder WAVs (bell, wooden_clap, electronic_horn, buzzer, complete); bundle them as `.process` resources
- [x] 2.2 Write failing tests for the pure `cueSound(for:)` mapping (bell for start/end/rest; selected WarningSound for the warning; complete for finish) (spec: audio-playback)
- [x] 2.3 Implement `cueSound(for:)` + `SoundAsset` — green
- [x] 2.4 Implement `AVAudioCuePlayer` (`prepare()` preloads via `Bundle.module`, `play(_:)` low-latency) with the `.playback`/`.duckOthers` session and `audio` background handling, all iOS-guarded; a light test that `prepare()`/`play()` don't throw on the host (spec: audio-playback)

## 3. Interruption & keep-awake seams

- [x] 3.1 Add `AudioInterruptionMonitoring` (`AsyncStream<InterruptionEvent>`) + a fake; concrete observes `AVAudioSession.interruptionNotification` (iOS-guarded) (spec: interruption-resilience)
- [x] 3.2 Add `IdleTimerControlling` protocol (`ProRoundsFeatureTimer`) + a fake; concrete `AppIdleTimer` in the app target (spec: workout-runtime)

## 4. Workout view model & display mapping (ProRoundsFeatureTimer)

- [x] 4.1 Add `WorkoutDisplayModel` + mapper (phase label, count-up/down numeral, total-remaining, ring progress 0…1, phase color, paused/finished); unit-test count-up vs count-down and progress (spec: workout-runtime)
- [x] 4.2 Write failing tests for `WorkoutViewModel` (over a `FakeTimeSource` engine + `SpyAudioCuePlayer` + fakes): onAppear starts + disables idle; snapshots update the display; pause/reset forward to the engine; finished re-enables idle; an interruption pauses then resumes (spec: workout-runtime / interruption-resilience)
- [x] 4.3 Implement `@MainActor @Observable WorkoutViewModel` (owns the snapshot task, transport intents, idle control, interruption subscription) — green

## 5. Workout screen & navigation

- [x] 5.1 Build `WorkoutView` (dumb): `TimerRing` + `PhaseBadge` + `TransportControls`, phase-tinted background, finished summary + Done; compose design-system components (spec: workout-runtime)
- [x] 5.2 Card tap starts the workout, `+`/swipe-Edit open the editor. **Deviation from plan:** navigation is by `Configuration` value (the app's `RootView` owns the `NavigationStack(path:)` + `navigationDestination` → `WorkoutView`) rather than a `TimerRoute.running` case, because `FeatureConfig` cannot import `FeatureTimer` (sibling features) — the list exposes an `onStartWorkout` callback. Correct layering (spec: config-list / workout-runtime)
- [x] 5.3 Composition root: build `RealTimeSource` + `AVAudioCuePlayer` + interruption monitor + `AppIdleTimer`; `ViewModelFactory.workout(_:)` wires the engine; `project.yml` gains `ProRoundsFeatureTimer` + `ProRoundsFoundationAudio` deps and `UIBackgroundModes: [audio]`; regenerate

## 6. Snapshots, UI test & verification

- [x] 6.1 Add workout-screen snapshot tests (round/rest/prep, paused, finished) light + dark
- [x] 6.2 Add an XCUITest target (project.yml + scheme test action): with `-uiTestSeed`, launch → tap the seeded card → assert the workout screen → pause → reset → back
- [x] 6.3 `./scripts/test.sh` + `./scripts/coverage.sh` green (engine included, player excluded as platform-edge, views excluded); `./scripts/lint.sh` strict clean; `./scripts/snapshot.sh` green
- [x] 6.4 Automated: app builds + launches with the audio background mode + session config; all phases (prep/round/rest/paused/finished) render light+dark via WorkoutContentView snapshots; the XCUITest drives start→pause→resume→reset. **MANUAL-ONLY (can't automate here):** actually hearing the cues, music-ducking, and locked-screen background firing require a human on device/simulator audio — engine timing/cue-order is exhaustively unit-tested, so these are audio-output checks only.
- [x] 6.5 Module graph compiles (FoundationAudio/FeatureTimer stay macOS-buildable via guards; no sibling-feature import); `openspec validate workout-runtime` clean; README updated

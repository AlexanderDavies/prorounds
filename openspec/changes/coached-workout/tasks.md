## 1. The cue-plan seam

The seam that keeps the engine ignorant of coaching. Everything else depends on getting it right.

- [ ] 1.1 Write failing tests for a `PlannedCue` value: a cue, an offset from round start, and the ticker strings, all resolved
- [ ] 1.2 Define `PlannedCue` and the `RoundCuePlanning` protocol in `ProRoundsFoundationAudio` — it deals in `AudioCue`, and putting it here is what lets `ProRoundsFeatureTimer` use it without touching coaching
- [ ] 1.3 Give the protocol a no-op default implementation and test that it plans nothing, so an uncoached workout needs no special case anywhere
- [ ] 1.4 Assert the seam takes **offsets only** — it must expose no way to express a delay, a sleep, or a clock

## 2. Engine: firing planned cues (test-first, against FakeTimeSource)

- [ ] 2.1 Write a failing test: a cue planned at a 30s offset fires exactly once, at that instant on the fake clock
- [ ] 2.2 Write failing tests: several cues fire in ascending offset order; a clock jump past several offsets fires all of them, in order, none skipped or repeated
- [ ] 2.3 Write a failing test: an offset beyond the round's length never fires and the round still ends on time
- [ ] 2.4 Implement plan firing in `processTick`, driven from the same crossing test as the round-end warning rather than a second mechanism
- [ ] 2.5 Write failing tests for transport: no cue fires while paused; cues not yet reached still fire after resume at their round-relative offsets; reset discards the abandoned round's plan
- [ ] 2.6 Write the regression that matters: the same workout run with and without a plan puts **every phase transition and every non-coaching cue at an identical instant**
- [ ] 2.7 Confirm every pre-existing engine test passes unchanged, with no edits to their expectations
- [ ] 2.8 Confirm `ProRoundsFeatureTimer` still has no dependency on `ProRoundsFoundationCoaching` — the architectural test from the previous change must still pass

## 3. Audio: speaking a clip

- [ ] 3.1 Write failing tests for a spoken `AudioCue` case carrying a file URL, including that it compares equal only for the same clip and that the existing cases are unchanged
- [ ] 3.2 Add the case, carrying a URL rather than a phrase id so the audio module needs no coaching dependency
- [ ] 3.3 Play the clip in `AVAudioCuePlayer` alongside the bundled sounds
- [ ] 3.4 Write a failing test: an unreadable clip does not crash and leaves the workout unaffected
- [ ] 3.5 Confirm the existing interruption and background-audio tests pass unchanged
- [ ] 3.6 Test that a phase-boundary cue still plays while a spoken clip is playing — the bell is the more important sound

## 4. The planner

- [ ] 4.1 Write failing tests: a coached configuration plans calls; an uncoached one plans nothing; a workout type with no script plans nothing rather than failing
- [ ] 4.2 Implement `CoachCuePlanner` in `ProRoundsFoundationCoaching`, adding its dependency on `ProRoundsFoundationAudio` (Foundation → Foundation)
- [ ] 4.3 Write a failing test: with entitlement locked the plan is empty, and the workout emits exactly what an uncoached one does at the same instants
- [ ] 4.4 Test clip resolution through the stored naming convention, including that a shared phrase ignores it
- [ ] 4.5 Write a failing test: a phrase whose clip is missing is dropped from the plan and the round runs normally
- [ ] 4.6 Test that the plan is deterministic for the same configuration, round index and length
- [ ] 4.7 Test that rest and prep plan nothing

## 5. The ticker

- [ ] 5.1 Write failing view-model tests: a punch call exposes both conventions and its modifier; a non-punch call exposes one line and no empty second line
- [ ] 5.2 Implement the ticker state on the workout view model, fed by the plan's resolved strings
- [ ] 5.3 Write failing tests: the ticker clears during rest and does not retain the last call; an uncoached workout has no ticker at all
- [ ] 5.4 Build the ticker view in the design system — names prominent, numbers above, modifier beneath
- [ ] 5.5 Give it an accessible description conveying the call and modifier as one phrase, not disconnected fragments
- [ ] 5.6 Test that every call that fires reaches the ticker — it is the whole channel for a deaf or hard-of-hearing user, not a decoration

## 6. The coaching chip and sheet

- [ ] 6.1 Write failing view-model tests: the chip shows the current level, is absent for workout types with no script, and is unavailable once running
- [ ] 6.2 Add the chip above the transport on the idle workout screen
- [ ] 6.3 Write a failing test: changing the level from the chip persists to the same `Configuration.coachingLevel` and the list reflects it — two entry points, one stored value
- [ ] 6.4 Build the sheet, mirroring the naming-convention control with an example of the coach's words per option
- [ ] 6.5 Test that the convention set here and in Settings are the same stored preference

## 7. The minimal running screen

- [ ] 7.1 Write failing view-model tests: with the preference on, a coached round keeps time, phase and ticker and hides the rest
- [ ] 7.2 Implement it, and test that changing the preference takes effect on the next coached round without a relaunch

## 8. Composition root

- [ ] 8.1 Build the planner from catalog, settings and entitlement in `AppEnvironment` and inject it
- [ ] 8.2 Write a failing test: a catalog that fails to load degrades to coaching unavailable rather than preventing launch — a content problem must never cost the user their timer
- [ ] 8.3 Test that nothing outside the composition root constructs a planner

## 9. Gates and docs

- [ ] 9.1 `scripts/lint.sh` clean
- [ ] 9.2 `scripts/test.sh` green, including every pre-existing engine and audio test unedited
- [ ] 9.3 `scripts/coverage.sh` at or above 90%, with the engine included as always
- [ ] 9.4 **BLOCKED — needs full Xcode.** Snapshot references for the ticker, chip and minimal screen; and the `ConfigCard` badge snapshot still outstanding from `coaching-config`. Command Line Tools has no XCTest, so these targets do not build here. Run `RECORD=1 ./scripts/snapshot.sh` under full Xcode, review the PNGs, commit
- [ ] 9.5 **BLOCKED — needs a simulator.** Drive a coached workout end to end: start, hear calls, background, take a call, resume, reach the bell. A timer bug is invisible in a screenshot, and this is the only check that exercises real audio against a real clock
- [ ] 9.6 Update `README.md` and `docs/COACHING_UX_BRIEF.md` per CLAUDE.md §0.3, recording Decision 3 as implemented and the feature as complete

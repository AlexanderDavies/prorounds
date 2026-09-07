# round-timer-engine Specification

## Purpose
TBD - created by archiving change round-timer-engine. Update Purpose after archive.
## Requirements
### Requirement: Honours the configured sequence exactly

The engine SHALL sequence a workout as `prep → (round → rest) × N` and SHALL NOT emit a rest after the final round (invariant §0.6.3). The round count and phase indices SHALL match the configuration with no off-by-one.

#### Scenario: Three-round workout produces the exact phase order

- **WHEN** a 3-round workout with non-zero prep runs to completion (driven by a fake clock)
- **THEN** the phases observed are: preparing, round 1, rest after 1, round 2, rest after 2, round 3, finished — with no rest after round 3

#### Scenario: Round indices are 1-based and bounded by the count

- **WHEN** a workout of N rounds runs
- **THEN** round phases are indexed 1…N and no `round(index:)` outside that range is ever emitted

### Requirement: Prep is skipped when zero

The engine SHALL begin at round 1 when prep duration is zero, rather than emitting a zero-length preparing phase.

#### Scenario: Zero prep starts at round 1

- **WHEN** a workout whose prep duration is 0 is started
- **THEN** the first phase is round 1, not preparing

### Requirement: Monotonic-deadline timing without drift

Each phase SHALL be timed by an absolute deadline computed from the injected monotonic clock; `remaining` SHALL be `deadline − now`, never a decremented tick counter. A slow, coarse, or missed tick SHALL NOT change when a phase ends.

#### Scenario: A coarse tick still ends the phase at the true deadline

- **WHEN** a 60-second round is advanced by the fake in irregular jumps (e.g. 0.2s, then 40s, then 25s) that overshoot the deadline
- **THEN** the round ends exactly at its deadline and the reported `remaining` never goes negative or drifts from `deadline − now`

#### Scenario: Long gap between ticks does not lose or add time

- **WHEN** no tick arrives for longer than a phase and the clock is then advanced past several deadlines at once
- **THEN** the engine transitions through exactly the phases whose deadlines were crossed, ending in the correct phase

### Requirement: Pause and resume preserve remaining time

`togglePause()` SHALL freeze the workout, capturing the current `remaining`; a subsequent `togglePause()` SHALL resume by rebuilding the deadline as `now + remaining`. Elapsed time SHALL NOT accrue while paused, and no cue SHALL fire due to time passing while paused.

#### Scenario: Time does not advance while paused

- **WHEN** a round with 30s remaining is paused, the fake clock is advanced 10s, then resumed
- **THEN** on resume the round still has 30s remaining and completes 30s of running time later

#### Scenario: Snapshot reports the paused state

- **WHEN** the workout is paused
- **THEN** the current snapshot's `isPaused` is true and the phase is unchanged

### Requirement: Reset returns to the initial state

`reset()` SHALL stop the workout and return the engine to its pre-start state (no active phase progression, transport idle), from which `start()` can run the full sequence again.

#### Scenario: Reset then restart runs the full sequence again

- **WHEN** a running workout is reset partway through and then started again
- **THEN** it runs the complete `prep → (round → rest) × N → finished` sequence from the beginning

### Requirement: Round-end warning fires at the configured lead

The engine SHALL fire the round-end warning cue at `roundDeadline − warningLead`, and SHALL NOT fire it at all when `warningLead` is 0. The warning SHALL never fire after the round has ended nor when the lead exceeds the round duration boundary.

#### Scenario: Warning fires once per round at the lead time

- **WHEN** rounds are 60s with a 10s warning lead
- **THEN** the round-end warning cue fires once per round, at 50s into each round (10s before its end)

#### Scenario: Zero lead suppresses the warning entirely

- **WHEN** the warning lead is 0
- **THEN** no round-end warning cue is ever emitted

### Requirement: Cues fire in the correct order from the engine

The engine SHALL emit `AudioCue`s at phase transitions and the warning instant — round start, round-end warning, round end, rest start, and workout complete — in the order the workout dictates, independent of any view.

#### Scenario: Two-round workout emits cues in exact order

- **WHEN** a 2-round workout with a non-zero warning lead and a rest between rounds completes
- **THEN** the recorded cue order is: round start, round-end warning, round end, rest start, round start, round-end warning, round end, workout complete — with no rest-start or round-end after the final round

### Requirement: Snapshots expose remaining, elapsed, and totals

The engine SHALL publish `Sendable` snapshots carrying the current phase, remaining in phase, elapsed in phase, elapsed total, total workout duration, round count, a paused flag, and a **run-state (started) flag**. Both elapsed-in-phase and remaining SHALL be available so the display can show either count direction without the engine branching on it. **Prep does not accrue toward `elapsedTotal`** — it is a lead-in, so the workout clock (`totalDuration` and `elapsedTotal`, hence total-remaining) covers only rounds + rest and starts advancing at round 1. The started flag SHALL be false before `start()` and after `reset()`, and true once the timeline has begun — so the display can distinguish an idle (not-yet-started) screen from a running one.

#### Scenario: Remaining and elapsed are consistent within a phase

- **WHEN** a snapshot is taken mid-phase
- **THEN** `remaining + elapsedInPhase` equals the current phase's duration, and `elapsedTotal` equals the sum of fully-elapsed prior **round/rest** phases plus (for a round/rest phase) `elapsedInPhase`

#### Scenario: Prep does not advance the total

- **WHEN** a snapshot is taken during the prep phase
- **THEN** `elapsedTotal` is 0 and the total-remaining equals the full rounds+rest total; only when round 1 begins does `elapsedTotal` start increasing

#### Scenario: The pre-start and post-reset snapshot report not-started

- **WHEN** a snapshot is read before the engine is started, or after it is reset
- **THEN** the snapshot's started flag is false; and after `start()` the snapshot's started flag is true

### Requirement: Finished is a terminal state

On completing the final round the engine SHALL enter `finished` and stop advancing; it SHALL emit the workout-complete cue exactly once and produce no further phase transitions until reset or restart.

#### Scenario: Workout completes into a stable finished state

- **WHEN** the final round ends
- **THEN** the phase becomes `finished`, the workout-complete cue has fired exactly once, and advancing the clock further produces no additional transitions or cues

### Requirement: The engine emits injected per-round cues at their offsets
The engine SHALL accept, per round, a plan of cues with offsets from that round's start, and SHALL
emit each as its offset is crossed, using the same monotonic-deadline arithmetic as its own cues. It
SHALL treat the plan as opaque data and SHALL NOT depend on what the cues mean.

#### Scenario: A planned cue fires at its offset
- **WHEN** a round is given a cue at a 30-second offset and the fake clock advances past it
- **THEN** that cue SHALL be emitted once, at that instant

#### Scenario: Cues fire in offset order
- **WHEN** several cues are planned in one round
- **THEN** they SHALL be emitted in ascending offset order

#### Scenario: A tick that crosses several offsets fires all of them
- **WHEN** the clock jumps past several planned offsets at once
- **THEN** every crossed cue SHALL be emitted, in order, none skipped and none repeated

#### Scenario: No cue fires twice
- **WHEN** ticks continue after a planned cue has fired
- **THEN** it SHALL NOT fire again

#### Scenario: An empty plan changes nothing
- **WHEN** a round has no planned cues
- **THEN** the engine SHALL behave exactly as it does without the feature

### Requirement: Planned cues never affect timing
Planned cues SHALL NOT influence phase transitions, deadlines, the round count, or the workout total.

#### Scenario: Transitions are unaffected
- **WHEN** the same workout is run with and without a plan against the same fake clock
- **THEN** every phase transition SHALL occur at an identical instant in both runs

#### Scenario: A plan extending past the round is truncated
- **WHEN** a plan contains an offset beyond the round's length
- **THEN** that cue SHALL NOT fire and the round SHALL end on time

### Requirement: Planned cues respect pause, resume and reset
Planned cues SHALL follow the same rules as the engine's own cues under transport control.

#### Scenario: Pausing suppresses pending cues
- **WHEN** the workout is paused
- **THEN** no planned cue SHALL fire while paused

#### Scenario: Resuming preserves the remaining plan
- **WHEN** the workout resumes after a pause
- **THEN** cues not yet reached SHALL still fire at their offsets relative to the round, with the
  pause excluded — the same deadline recomputation the engine already performs

#### Scenario: Reset clears the plan
- **WHEN** the workout is reset
- **THEN** no cue from the abandoned round SHALL fire afterwards


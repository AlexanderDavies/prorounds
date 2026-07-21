## ADDED Requirements

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

The engine SHALL publish `Sendable` snapshots carrying the current phase, remaining in phase, elapsed in phase, elapsed total, total workout duration, round count, and paused flag. Both elapsed-in-phase and remaining SHALL be available so the display can show either count direction without the engine branching on it.

#### Scenario: Remaining and elapsed are consistent within a phase

- **WHEN** a snapshot is taken mid-phase
- **THEN** `remaining + elapsedInPhase` equals the current phase's duration, and `elapsedTotal` equals the sum of fully-elapsed prior phases plus `elapsedInPhase`

### Requirement: Finished is a terminal state

On completing the final round the engine SHALL enter `finished` and stop advancing; it SHALL emit the workout-complete cue exactly once and produce no further phase transitions until reset or restart.

#### Scenario: Workout completes into a stable finished state

- **WHEN** the final round ends
- **THEN** the phase becomes `finished`, the workout-complete cue has fired exactly once, and advancing the clock further produces no additional transitions or cues

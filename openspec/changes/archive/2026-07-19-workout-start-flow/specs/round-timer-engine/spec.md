## MODIFIED Requirements

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

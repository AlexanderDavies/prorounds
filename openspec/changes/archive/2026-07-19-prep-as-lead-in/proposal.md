## Why

Prep time is a lead-in before the fight starts, not part of the workout. Today it's folded into the
"total time" shown on the config card, the editor, the running clock, and the saved session — which
overstates how long the user actually trained. Total should measure **actual work + rest**, with prep
excluded. (From hands-on use — `changes.md` #3.)

## What Changes

- **Total = rounds + rest, prep excluded.** The single-source total calculator drops the prep term, so
  every "total" (config card, editor live total, session total, the running total-remaining) reflects
  only round time + rest time.
- **The running clock treats prep as a lead-in.** Prep no longer accrues toward `elapsedTotal`, so
  during the prep phase the total-remaining shows the **full** rounds+rest time and only starts
  counting down at round 1. The prep phase still plays and counts down on its own.
- **Default prep time → 20 seconds** (was 10).

## Capabilities

### Modified Capabilities
- `duration-formatting`: the single-source total-workout-duration is `round×N + rest×(N−1)` — prep excluded.
- `workout-configuration`: `Configuration.totalDuration` (via the shared calculator) now excludes prep.
- `round-timer-engine`: prep does not accrue toward `elapsedTotal`; the workout clock starts at round 1.
- `session-model`: a session's total duration is the workout time (rounds + rest), excluding prep.

## Impact

- `WorkoutMath.totalDuration` (drop the prep term + param), `Configuration`/`ConfigurationDraft` call
  sites, `RoundTimerEngine` (exclude prep from `elapsedTotal`), `ConfigurationDraft.prepSeconds` default.
- Update affected tests (duration/config math e.g. 12×3:00/1:00 total 47:10 → **47:00**; the engine's
  elapsed-total-during/after-prep; the config-row total) and re-record the affected snapshots (config
  list + editor totals).
- The chart's **active minutes** metric (round time only) is **unchanged** — it already excluded rest
  and prep. No behavioural change to sequencing, cues, or the no-rest-after-final-round invariant.

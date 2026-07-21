## Context

Total time and the running clock both include prep today. The user wants prep treated as a lead-in:
excluded from every "total" and from the workout clock (which should start at round 1). Prep still
plays as a phase. `changes.md` #3.

## Goals / Non-Goals

**Goals:** total = rounds + rest everywhere; prep excluded from `elapsedTotal`; default prep 20s.

**Non-Goals:** no change to sequencing, cues, the no-rest-after-final invariant, or the chart's active-
minutes metric (already round-only).

## Decisions

- **Single-source calculator drops prep.** `WorkoutMath.totalDuration` becomes `round×N + rest×(N−1)`
  and drops its `prep` parameter (removing it, rather than ignoring it, keeps the intent honest). Zero
  rounds ⇒ `.zero`. `Configuration.totalDuration` and `ConfigurationDraft.total` update their call sites.
  Because it's the single source, config card / editor / session / running total all follow.
- **Engine excludes prep from `elapsedTotal` in two places.** (1) On a phase transition, only add the
  completed phase's duration to `elapsedBeforeCurrentPhase` when it is **not** the prep phase. (2) In
  `makeSnapshot`, count `elapsedInPhase` toward `elapsedTotal` only for round/rest phases (0 during
  prep). So during prep `elapsedTotal == 0` and total-remaining shows the full rounds+rest; at round 1
  the clock starts. `totalDuration` already follows from the calculator.
- **Default prep 20s** — `ConfigurationDraft.prepSeconds = 20`.

## Risks / Trade-offs

- **Test churn** → update the math/config/engine/config-row assertions (e.g. 47:10 → 47:00) and add an
  engine test that prep doesn't advance `elapsedTotal`; re-record the config-list + editor total snapshots.
- **Coherence during prep** → total-remaining is intentionally static during prep; that's the "lead-in"
  reading the user confirmed.

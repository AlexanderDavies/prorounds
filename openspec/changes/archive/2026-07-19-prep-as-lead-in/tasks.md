## 1. Calculator — total excludes prep

- [x] 1.1 Update `WorkoutMath.totalDuration` tests: 12×3:00/1:00 → 47:00; zero rounds → 0; add "prep doesn't change the total" (spec: duration-formatting)
- [x] 1.2 `WorkoutMath.totalDuration` = `round×N + rest×(N−1)`; drop the `prep` param; zero rounds ⇒ `.zero`; update `Configuration.totalDuration` + `ConfigurationDraft.total` call sites — green (spec: workout-configuration)

## 2. Engine — prep is a lead-in

- [x] 2.1 Write a failing engine test: during prep `elapsedTotal == 0` and total-remaining == full rounds+rest; after prep the clock starts at round 1; fix the change-#2 snapshot-consistency test to the new numbers (spec: round-timer-engine)
- [x] 2.2 Exclude prep from `elapsedTotal`: don't add the prep phase's duration to `elapsedBeforeCurrentPhase` on transition; don't count `elapsedInPhase` during prep in `makeSnapshot` — green

## 3. Default prep + downstream tests

- [x] 3.1 `ConfigurationDraft.prepSeconds` default `10 → 20`
- [x] 3.2 Update the config-row / session assertions that referenced the old totals (e.g. `ConfigDisplayMapper` total 47:10 → 47:00); confirm the chart's active-minutes is unaffected

## 4. Verification

- [x] 4.1 `./scripts/test.sh` + `./scripts/coverage.sh` green; `./scripts/lint.sh` strict clean
- [x] 4.2 Re-record the affected snapshots (config list populated + editor totals) and review they read 47:00
- [x] 4.3 `openspec validate prep-as-lead-in` clean; README unaffected (behaviour, not build)

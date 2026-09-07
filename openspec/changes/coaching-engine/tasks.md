## 1. Package scaffold

- [x] 1.1 Add `ProRoundsFoundationCoaching` as a `.library` and `.target` in `Package.swift`; dependencies limited to `ProRoundsFoundationTiming` and `ProRoundsFoundationUtilities`. **Resources are `.process` per JSON file + `.copy("Resources/clips")`** — `.process` on the directory flattens the tree and collides the 26 forked phrases (`numbers/jab.m4a` vs `names/jab.m4a`)
- [x] 1.2 Regenerate the Xcode project and confirm it still builds. The product is deliberately **not** added to the app target in `project.yml` — per the design's migration plan, nothing links coaching until change 2 wires it
- [x] 1.3 Add `ProRoundsFoundationCoachingTests` and confirm `scripts/test.sh` picks it up
- [x] 1.4 Copy `phrases.json`, `beginner_shadow.json`, `beginner_bag.json` into `Sources/ProRoundsFoundationCoaching/Resources/` alongside the committed `clips/`
- [x] 1.5 Confirm the package builds and the test target runs green before any logic is written — includes a regression test that `clips/{numbers,names,shared}` survive bundling at 26/26/63, which is what caught the `.process` flattening

## 2. Fixtures from the Python reference

Everything below is verified against these files, so they come first. `scripts/coach-script.py` is
normative: where it and the README disagree, the Python wins.

- [x] 2.1 Add a `--json` output mode to `coach-script.py preview`, emitting `[{offsetMs, phraseId, kind}]` — it currently only prints human-readable output
- [x] 2.2 Add a `seed-vectors` subcommand emitting, for a set of `(configID, roundIndex)` pairs: the FNV-1a digest, the first N `next_u64()` values, and the first N `unit()` values as exact hex bit patterns
- [x] 2.3 Add `scripts/gen-coach-fixtures.sh` regenerating every fixture in one command, so a reference change is one step, not a manual sweep
- [x] 2.4 Generate schedule fixtures for both scripts across round lengths 4/5/45/60/120/180/240/300s × roundIndex 0-2 — 48 files, 4 of which exercise the empty-schedule guard path. Schedules are convention-independent (`schedule()` takes no convention), so fixtures are **not** forked by convention. **No `.5` fixture:** exact `.5` pre-rounding values do not occur — 0 across 212,748 samples spanning both scripts, 45-600s, 4 indices — so the rounding mode must be unit-tested directly instead (see 5.9)
- [x] 2.5 Commit fixtures under `Tests/ProRoundsFoundationCoachingTests/Fixtures/` and document regeneration in `docs/coaching/README.md`

## 3. Deterministic RNG (test-first, against 2.2)

- [ ] 3.1 Write failing tests for `SplitMix64` asserting the exact `next_u64()` values from the 2.2 vectors; plus same-seed determinism and different-seed divergence
- [ ] 3.2 Implement `SplitMix64` as a `RandomNumberGenerator` with the reference constants (`0x9E3779B97F4A7C15`, `0xBF58476D1CE4E5B9`, `0x94D049BB133111EB`)
- [ ] 3.3 Write failing tests for `fnvSeed(configID:roundIndex:)` over the UTF-8 bytes of `"<configID>#<roundIndex>"`, asserting the 2.2 digests; **`roundIndex` is zero-based** (`coach-script.py:283`, `--round-index` defaults to 0)
- [ ] 3.4 Implement the FNV-1a 64 seed and make the tests pass
- [ ] 3.5 Implement `unit()` as `Double(next >> 11) / Double(1 << 53)` and assert bit-identity against the 2.2 hex patterns
- [ ] 3.6 Implement `weighted(_:weight:)` including the reference's trailing `return items[-1]` fallback, with a test that reaches it

## 4. Catalog decoding and validation (test-first)

- [ ] 4.1 Write failing tests for decoding `phrases.json` into `CoachPhrase`, covering forked vs shared text and all five kinds
- [ ] 4.2 Implement `CoachPhrase`, `CoachKind`, `ClipKind` and the catalog decoder; an unknown kind must throw, not default
- [ ] 4.3 Write failing tests for decoding a script into `CoachScript`/`CoachSegment`/`CoachGuards`, including pools, mix, cadence range and pinned cues
- [ ] 4.4 Implement script decoding; assert `voice`/`intent` decode as author notes and are never exposed as speakable text
- [ ] 4.5 Write failing tests for the load-time integrity rules: unknown pool id, no-repeat window ≥ pool size, unanswerable `follows` tag, segment shares not summing to 1
- [ ] 4.6 Implement `validate()` mirroring `coach-script.py validate`, throwing typed errors that name the offending id
- [ ] 4.7 Add a test asserting every phrase resolves to its clip file(s) in the bundle — 26 `numbers`, 26 `names`, 63 `shared`
- [ ] 4.8 Add a test asserting the bundled `phrases.json` is byte-identical to `docs/coaching/phrases.json`, so the two copies cannot drift
- [ ] 4.9 Implement `clipResource(for:convention:)` and test that shared phrases ignore the convention — this is the only place convention matters in this change

## 5. Scheduler (test-first, against 2.4)

- [ ] 5.1 Write the failing byte-identity test: `schedule(...)` equals the committed fixture for each script × round length × roundIndex
- [ ] 5.2 Implement segment placement by proportional share, carrying `t` and `segStart` as `Double` milliseconds per the design
- [ ] 5.3 Implement pinned-cue placement first, with `minGapMs` reserved either side and silent drop when the round is too short
- [ ] 5.4 Implement kind drawing from `mix`, with the two adjacency rules: force combo on a repeated kind, and never a third consecutive non-combo
- [ ] 5.5 Implement per-kind no-repeat filtering, `follows` matching with `followsBoost`, `answerAfterNonCombo`, and `windowFromRoundEndMs`
- [ ] 5.6 Implement the combo-pool fallback when filtering leaves no candidate
- [ ] 5.7 Implement `nudge()` clear of the warning cue, and the end-of-round guard that drops a call whose `estMs` would breach `roundEndGuardMs`
- [ ] 5.8 Implement cadence advance as `max(drawn, estMs + minGapMs)`
- [ ] 5.9 Emit offsets with `.rounded(.toNearestOrEven)` to match Python's `round()`. Test the rounding helper **directly** on 0.5/1.5/2.5/-0.5 — an end-to-end fixture cannot reach it, since exact `.5` never arises from the cadence walk (see 2.4)
- [ ] 5.10 Make the byte-identity test from 5.1 pass for every fixture

## 6. Property and invariant tests

- [ ] 6.1 Property test over many generated rounds: no cue ends inside `roundEndGuardMs` — asserted as behaviour, so a clip re-record fails loudly rather than drifting
- [ ] 6.2 Property test: no cue starts before `roundStartDelayMs`
- [ ] 6.3 Property test: every offset falls within the round; a round too short for any call returns an empty schedule and does not throw
- [ ] 6.4 Property test: no three consecutive non-combo calls, and no per-kind repeat inside its window
- [ ] 6.5 Test that the scheduler exposes no clock dependency and no way to extend the round — the type takes no `TimeSource`

## 7. Cross-check against the reference

- [ ] 7.1 Run `scripts/coach-script.py validate` and `stats`; record the delivered-vs-authored mix and sanity-check it rather than assuming the reference is correct
- [ ] 7.2 Reconcile any divergence between the Swift port and the Python; where the README's prose disagrees with the Python, correct the README
- [ ] 7.3 Confirm `estMs`-dependent behaviour still holds after the trimmed re-record

## 8. Gates and docs

- [ ] 8.1 `scripts/lint.sh` clean
- [ ] 8.2 `scripts/test.sh` green
- [ ] 8.3 `scripts/coverage.sh` passes with the scheduler included in the gate — it is never excluded
- [ ] 8.4 Update `README.md` (module graph and package list) and `docs/coaching/README.md` (fixture regeneration, Swift port status) per CLAUDE.md §0.3

## Context

The coaching content is finished and committed: 89 phrases, 115 measured clips, two scripts, and
`scripts/coach-script.py` — a working reference implementation of the selection algorithm, with
`validate`, `preview` and `stats` subcommands. `docs/coaching/README.md` §"Selection algorithm (what
Swift must reproduce)" is normative.

What does not exist is any Swift. This change builds the pure half: catalog plus scheduler, no audio,
no UI, no `Configuration` field. That split exists because scheduling is exhaustively verifiable
without a device — the Python reference emits the exact expected sequence — whereas playback and UI
are not. Keeping them apart means a timing bug surfaces as a failing unit test, not as a wrong-sounding
workout.

Constraints from `CLAUDE.md` and the architecture guide: Foundation-layer packages may not reach
Data, Feature, or DesignSystem; everything with side effects sits behind a protocol seam; TDD is
mandatory; the engine is never excluded from the 90% coverage gate.

## Goals / Non-Goals

**Goals:**
- A `CoachCueScheduler` whose output is byte-identical to `coach-script.py preview` for the same
  inputs, proven by committed fixtures rather than by inspection.
- A typed catalog that fails loudly at load, enforcing the same integrity rules as
  `coach-script.py validate`, so an authoring mistake cannot reach the scheduler.
- Determinism that survives OS upgrades and different machines.
- Zero coupling to the clock: this package is an output of the timer, never an input.

**Non-Goals:**
- Playing audio, crossfading, or touching `AVAudioSession` (change 3).
- A `Configuration` field, migration, `SettingsStore` key, or `EntitlementStore` (change 2).
- The dual-convention ticker or any view (change 3).
- Intermediate/Advanced levels, rest-phase coaching, or a prep call-in — unauthored by design.

## Decisions

**Port the algorithm rather than reinterpret it.** `coach-script.py` is treated as the specification
and Swift as the port. Where the prose in the README and the Python disagree, the Python wins and the
README gets corrected. *Alternative considered:* writing the Swift from the README alone and treating
matching output as a happy accident — rejected, because the adjacency and fallback rules have enough
edge cases that "looks right" is not a standard, and the fixtures would then prove nothing.

**Fixtures are generated, committed, and regenerable.** A small script emits `preview --json` for both
scripts across a spread of round lengths and seeds into `Tests/.../Fixtures/`. Tests compare against
those files. *Alternative considered:* shelling out to Python during the test run — rejected: it
breaks hermeticity, needs a Python on CI, and makes the suite slow.

**`SplitMix64` as an explicit `RandomNumberGenerator`.** Seeded by FNV-1a 64 over the UTF-8 bytes of
`"<configID>#<roundIndex>"`. *Alternative considered:* `SystemRandomNumberGenerator` seeded somehow —
impossible, it cannot be seeded, and its sequence is not stable across OS versions. That instability
would silently break replay, which Decision 1 of the UX brief depends on.

**Clips are `.copy`, not `.process`.** SwiftPM's `.process` flattens a resource directory, and the 26
forked phrases share a filename across `numbers/` and `names/` — `jab.m4a` exists in both — so
processing the directory fails the build outright (and would have silently dropped half the clips had
it not). The three JSON files are `.process`ed individually; `clips/` is `.copy`ed, preserving the
`clips/<convention>/<id>.m4a` layout the docs define and the generator produces. Lookup is therefore
`url(forResource:withExtension:subdirectory: "clips/<convention>")`. *This corrects the original
design*, which said to mirror `ProRoundsFoundationAudio`'s `.process("Resources")` — that package's
resources are flat, ours are nested.

**Resources move into the package; `docs/coaching/` stays the authoring home.** The catalog and script
JSON are copied into `Sources/ProRoundsFoundationCoaching/Resources/` at build time by the existing
generator workflow, alongside the clips already committed there. *Alternative considered:* loading from
`docs/` at runtime — impossible in a shipped bundle. *Also considered:* making the package the only
home and deleting the docs copies — rejected, because `coach-script.py` and the authoring workflow
read from `docs/`, and moving them would break the tooling that validates the content.

**The scheduler returns a whole round at once, not a cursor.** `schedule(script:configID:roundIndex:
roundLength:) -> [ScheduledCue]`. *Alternative considered:* an iterator advanced by the timer —
rejected: it would give the scheduler an implicit dependency on time and make determinism far harder
to test. A precomputed array is trivially assertable and lets change 3 hand offsets straight to the
existing monotonic-deadline cue mechanism.

**Mirror the reference's float arithmetic exactly, including its rounding mode.** The Python carries
`t`, `seg_start` and `start` as `float` milliseconds for the whole walk and converts only at emit, via
`int(round(...))`. Python's `round()` is **round-half-to-even**; Swift's `rounded()` defaults to
**round-half-away-from-zero**, so a naive port diverges on every exact `.5` offset. Swift SHALL use
`Double` for the walk and `.rounded(.toNearestOrEven)` at emit. *Alternative considered:* reworking the
walk in integer milliseconds, which is cleaner Swift — rejected for this change, because it would
change draw boundaries and break byte-identity with the reference. If integerising is wanted later it
must be done in the Python first, with fixtures regenerated from it.

**`estMs` is trusted as measured truth.** The values are now real trimmed durations, not estimates, so
the end-of-round guard arithmetic is exact rather than defensive. Regenerating clips rewrites them;
the tests must therefore assert guard *behaviour*, not hardcoded millisecond totals that a re-record
would invalidate.

## Risks / Trade-offs

- **Swift and Python diverge subtly** (share arithmetic, offset rounding, tie-breaks in weighted draws)
  → the two known traps are named as decisions above: `.toNearestOrEven` at emit, and `unit()` defined
  as `Double(next >> 11) / Double(1 << 53)`, which is exactly representable in IEEE-754 and so is
  bit-identical across both languages. Fixtures cover both scripts across several round lengths and
  round indices; a `.5` boundary is included deliberately.
- **Fixtures ossify a bug.** If the Python has a defect, Swift faithfully reproduces it → `validate`
  and `stats` are run over the catalog as part of this change, and the delivered-mix figures are
  sanity-checked against the authored mix rather than assumed.
- **A clip re-record shifts every `estMs`** and could push a call past a guard → the guard is asserted
  as a property ("no cue ends inside `roundEndGuardMs`") over generated rounds, so a re-record either
  passes or fails loudly rather than drifting.
- **Resource duplication between `docs/` and the package** could let the two drift → a test asserts the
  bundled catalog is byte-identical to the authoring copy, so drift fails CI.
- **Over-building.** This is a timer app; the scheduler is the one genuinely intricate piece, and the
  temptation is to generalise it for levels that are not authored → the API takes a concrete script and
  returns concrete cues; no level abstraction, no plugin seam, until a second level exists.

## Migration Plan

Additive and reversible. A new leaf package that nothing depends on yet; `Package.swift` and
`project.yml` gain one target each. Nothing in the app links it until change 2. Rollback is deleting
the package and its two manifest entries.

## Open Questions

- **Crossfade between calls** is assumed ~220ms in the mockups. It is a playback concern (change 3) and
  is deliberately not modelled here — but if it turns out the scheduler must reserve for it, `minGapMs`
  is the place, and that is a script-content change rather than a code change.

**Resolved while writing this design** (checked against `scripts/coach-script.py`, not assumed):
- `roundIndex` in the seed string is **zero-based**; the reference displays `round_index + 1` for
  humans but seeds with the raw value (`coach-script.py:283`).
- `weighted()` draws with `rng.unit() * total` and returns the last item if the accumulator never
  exceeds `x`; that fallback is reachable through float error and must be ported, not tidied away.

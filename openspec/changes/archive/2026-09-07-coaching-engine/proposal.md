## Why

The assisted-coaching content is authored and recorded — 89 phrases, 115 clips, two beginner scripts,
and a Python reference implementation of the selection algorithm — but none of it is reachable from
Swift. Nothing in the app can yet decide *which* call to make *when*.

That decision is pure logic, and it is the part most likely to be got wrong quietly: a scheduler that
drifts, repeats itself, or lets a cue still be speaking at the bell degrades the workout without ever
crashing. It is also the part that can be verified exhaustively without audio, a device, or a UI —
`scripts/coach-script.py preview` already emits the exact sequence Swift must reproduce, so every test
here is a deterministic comparison against a committed fixture. Building it first, alone, keeps that
verification honest; folding it into playback or UI work would bury a timing bug behind an AVAudio
session and a view model.

## What Changes

- **New package `ProRoundsFoundationCoaching`** — Foundation layer, depends only on
  `ProRoundsFoundationTiming` (for the `TimeSource` seam) and `ProRoundsFoundationUtilities`. No
  audio, no SwiftUI, no persistence.
- **A typed catalog** decoded from the committed `phrases.json` and the two script files, exposed as
  value types (`CoachPhrase`, `CoachScript`, `CoachSegment`, `CoachGuards`). Phrase IDs stay the
  single source of truth; nothing inlines call text.
- **`CoachCueScheduler`** — given a script, a `configID`, a `roundIndex` and a round length, returns
  the ordered `[ScheduledCue]` for that round: offset from round start, phrase ID, and kind.
  Deterministic and pure; it takes no clock and performs no I/O.
- **`SplitMix64` + FNV-1a seeding** as an explicit, tested `RandomNumberGenerator`, replacing any use
  of `SystemRandomNumberGenerator`, whose sequence is not stable across OS versions or machines.
- **The clip resource bundle** is declared on the new target so changes 2 and 3 can resolve a phrase
  ID to a file, but nothing in this change plays audio.
- **No** `Configuration` field, settings, entitlement seam, ticker, or playback — those are changes 2
  (`coaching-config`) and 3 (`coached-workout`).

## Capabilities

### New Capabilities
- `coaching-catalog`: decoding and validating the phrase catalog and script files into typed domain
  values; phrase/pool integrity rules that must hold at load time.
- `coaching-scheduler`: the seeded, arc-segmented selection algorithm that turns a script plus a
  round identity into an ordered cue schedule, including adjacency rules, no-repeat windows, pinned
  cues, and the end-of-round guard.
- `deterministic-rng`: the seeded generator (FNV-1a → SplitMix64) whose sequence must be reproducible
  across machines, OS versions, and the Python reference.

### Modified Capabilities
<!-- None. This change adds a leaf package and touches no existing requirement. The timer engine,
     audio cues, and workout runtime are read for context but not modified; coaching becomes a new
     cue kind on the existing engine only in change 3. -->

## Impact

- **New:** `Sources/ProRoundsFoundationCoaching/` (+ `Tests/`), a `.library` and `.target` entry in
  `Package.swift` with `resources: [.process("Resources")]`, and the target listed in `project.yml`.
- **Read, not modified:** `docs/coaching/phrases.json`, `docs/coaching/beginner_{shadow,bag}.json` —
  these move into the package's `Resources/` so the app can load them, and `docs/coaching/` remains
  the authoring home. Duplication is resolved by copying at build time, not by a second source of
  truth.
- **Reference implementation:** `scripts/coach-script.py` is normative for this change. Its
  `preview` output becomes committed test fixtures; a divergence is a bug in Swift, not in Python.
- **Risk:** the guard values (`roundEndGuardMs`, `minGapMs`, no-repeat windows) interact with the
  newly measured `estMs` durations. `coach-script.py validate` passes today; the Swift port must be
  checked against the same catalog rather than assumed equivalent.
- **Untouched invariants:** no network, no PII, no change to phase sequencing, round counts, or bell
  timing. This package cannot reach the clock.

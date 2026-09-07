## Why

Everything the coach needs exists and none of it is audible. The catalog, the scheduler and 115
recordings ship inside `ProRoundsFoundationCoaching`; a configuration can be marked coached; the
naming convention and minimal-screen preferences are stored. Nothing reads any of it during a
workout.

This change closes that, and it is the riskiest of the three because it is the only one that touches
the timer. The engine is the product: a monotonic-deadline clock that must not drift, double-fire, or
lose a round. Coaching has to become **a new kind of cue on that one timeline**, never a second
timeline running alongside it — a parallel scheduler would be the single most damaging thing this
feature could do, and it would fail quietly rather than crash.

## What Changes

- **Coaching cues fire from the existing engine.** The engine gains the ability to emit additional
  cues at offsets within a round, alongside the round-start, warning and round-end cues it already
  emits, from the same deadline arithmetic.
- **A cue plan is injected, not computed by the engine.** A `RoundCuePlanning` seam supplies, per
  round, a list of `(offset, cue, ticker text)`. The engine treats it as opaque data — it learns
  nothing about coaching, phrases, or entitlement.
- **`AudioCue` gains a case for a spoken clip**, carrying a resolved file URL so the audio module
  needs no dependency on coaching.
- **`AVAudioCuePlayer` plays a clip from a URL**, alongside its existing bundled sounds, and keeps
  the current interruption and background-audio behaviour.
- **The running screen gains the dual-convention ticker** — numbers small above names large, with the
  modifier beneath. It teaches the mapping passively and is the path for a deaf or hard-of-hearing
  user, for whom it is the *only* channel.
- **The idle workout screen gains a `Coach: Off ▾` chip** above the transport, opening a sheet that
  edits the same `Configuration.coachingLevel` the editor does and mirrors the naming-convention
  control.
- **The minimal-screen preference finally does something.**
- **Entitlement gating happens in the planner** — when coaching is not entitled, the plan is empty.
  Nothing else about the workout changes.

## Capabilities

### New Capabilities
- `coaching-playback`: how a coached round's calls are planned, gated, resolved to clips, and fired
  on the existing timeline.
- `coaching-ticker`: what the running screen shows for the current call, in both conventions.

### Modified Capabilities
- `round-timer-engine`: the engine emits injected per-round cues at their offsets, without learning
  what they are.
- `audio-cues`: a new cue case for a spoken clip identified by URL.
- `audio-playback`: the player plays a clip from a URL and keeps its interruption behaviour.
- `workout-runtime`: the running screen shows the ticker, honours the minimal preference, and offers
  the coaching chip when idle.
- `app-composition`: the composition root builds the planner from the catalog, settings and
  entitlement, and injects it.

## Impact

- **Engine risk is the whole story.** `RoundTimerEngine` is under a ≥90% coverage gate it is never
  excluded from, and its correctness is asserted against a `FakeTimeSource`. Every existing timing
  test must still pass unchanged, and the new behaviour must be provable with the clock stopped.
- **`ProRoundsFeatureTimer` must not gain a dependency on `ProRoundsFoundationCoaching`.** An
  architectural test added in the previous change asserts this, so the engine cannot reach the
  entitlement. The cue-plan seam exists to keep that true.
- **Audio:** `AudioCue`, `AudioCuePlayer` and `AVAudioCuePlayer`; interruption behaviour is
  regression territory, not new work.
- **Presentation:** `ProRoundsFeatureTimer` views and view model, plus design-system components for
  the ticker and chip.
- **Blocked here:** snapshot and XCUITest targets need XCTest, which Command Line Tools lacks. The
  `ConfigCard` snapshot from the previous change is still outstanding for the same reason.
- **Untouched invariants:** no network, no PII. Coaching must never move a phase boundary, change a
  round count, or delay the bell — and must degrade gracefully through an interruption.

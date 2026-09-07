## Context

Two changes have shipped. `ProRoundsFoundationCoaching` holds the catalog, the scheduler and 115
clips, all pure and none of it reachable at runtime. `Configuration` carries a coaching level and
`SettingsStore` carries the naming convention and minimal-screen preferences. Nothing plays.

This change touches the one part of the app that cannot be got wrong quietly. `RoundTimerEngine`
drives everything from an absolute monotonic deadline, emits `[AudioCue]` from `beginTimeline` and
`processTick`, and is verified end-to-end against a `FakeTimeSource`. Its correctness *is* the
product.

There is also a constraint from the previous change that shapes the whole design: an architectural
test asserts **`ProRoundsFeatureTimer` has no dependency on `ProRoundsFoundationCoaching`**. That was
written so the engine could never reach the entitlement. It is load-bearing, and the obvious
implementation — teaching the engine about coaching — would require deleting it.

## Goals / Non-Goals

**Goals:**
- Coaching calls fire from the existing timeline, from the same deadline arithmetic, as one more kind
  of cue.
- The engine gains a general capability and learns nothing about coaching, phrases or entitlement.
- The ticker carries every call, so a deaf or hard-of-hearing user loses nothing.
- Every existing timing test passes unchanged.

**Non-Goals:**
- Rest or prep coaching, or a prep call-in — unauthored in v1.
- Levels beyond Beginner; workout types beyond Shadow Boxing and Heavy Bag.
- Any paywall UI. The entitlement is consulted; nothing is sold.
- A coached-catalog tab. Still deferred until a second level exists.

## Decisions

**The engine takes a plan of `(offset, cue)`, not a coaching dependency.** A `RoundCuePlanning` seam
supplies, per round, cues with offsets from that round's start; the engine fires them from the same
deadline arithmetic it already uses for the warning cue. It never learns what they are.

*Alternative considered:* give the engine the catalog and scheduler directly. Simplest to write, and
rejected on two grounds — it would put the entitlement inside the clock's module, deleting the
architectural guard, and it would make every engine test carry coaching fixtures. *Also considered:* a
second scheduler driving cues off the engine's snapshot stream. Rejected outright: that is a second
timeline, drifting independently, and it would fail quietly rather than crash. The invariant is not
"coaching is accurate", it is "there is one clock".

**The plan carries its display text, already resolved.** Each entry holds the cue, the offset, and the
strings the ticker shows. This is what keeps `ProRoundsFeatureTimer` free of coaching types on the
*presentation* side as well as the timing side — otherwise the view model would import the catalog to
render a ticker and the guard would fall anyway.

**`AudioCue` gains a case carrying a file URL, not a phrase id.** A phrase id would force
`ProRoundsFoundationAudio` to depend on the coaching module to resolve it. A URL is already resolved,
so the audio layer stays a dumb player. *Trade-off:* `AudioCue` stops being a small closed enum of
app sounds. Accepted — the alternative pushes a dependency in the wrong direction.

**The planner lives in `ProRoundsFoundationCoaching`.** It is the only place that already knows the
catalog, the scheduler and clip resolution; it gains a dependency on `ProRoundsFoundationAudio`
(Foundation → Foundation, permitted). The composition root builds it from catalog + settings +
entitlement and injects it.

**The entitlement is consulted when the plan is built, before the round starts.** Not per cue, not
inside a tick. The plan is simply empty when locked, so the locked path is the uncoached path exactly
— nothing special-cased in the timing code, which is where a subtle difference would hide.

**A missing clip drops its call from the plan.** Not silence, not a crash. The clips are derived
artefacts that a regeneration could rename, and losing one call is a far better failure than losing
the workout.

**The coaching control is offered only while idle.** Changing the level mid-workout would change a
round's plan after it began. Rather than define what that means, the control is unavailable once
running.

## Risks / Trade-offs

- **A parallel timeline creeps in later** — someone adds a `Task.sleep` for a call because it is
  easier than extending the plan → the seam takes offsets only, with no way to express a delay, and
  the engine is the only thing holding a clock.
- **The engine's cue loop gains a branch and drifts.** `processTick` already handles the warning cue
  with a fired-once flag; a second such mechanism is where an off-by-one lives → planned cues are
  driven from the same crossing test, and a test asserts a clock jump past several offsets fires all
  of them exactly once.
- **Coverage hides the risk.** The engine is never excluded from the gate, but a plan-carrying test
  that only ever uses an empty plan would still pass → tests assert cue *instants* against the fake
  clock, not merely that cues appeared.
- **Interruption behaviour regresses.** A call mid-clip is new territory for the player → the existing
  interruption tests must pass unchanged, and the boundary cue must still play even if a call is
  speaking, because the bell matters more.
- **The ticker becomes decorative.** If it is treated as a nicety it will drift from what is spoken →
  it is specified as a complete channel, and every planned call must reach it.
- **Verification gap on this machine.** Snapshot and XCUITest targets need XCTest, which Command Line
  Tools lacks, so the visual work cannot be verified here. Anything requiring it is flagged blocked
  rather than assumed done — as the `ConfigCard` snapshot from the previous change already is.

## Migration Plan

Additive. No stored data changes; no schema change, so nothing to migrate. An uncoached configuration
produces an empty plan and behaves exactly as before, which is also the rollback path: an empty plan
is the current app.

## Open Questions

- **Crossfade between calls** was assumed ~220ms in the mockups and deliberately not modelled in the
  scheduler. It needs to be *heard* before it is specified. If it turns out the schedule must reserve
  for it, `minGapMs` in the script is the place, and that is content rather than code.
- **Whether a call should duck under the round-end bell** or simply overlap is a judgement best made
  by listening. The spec requires only that the bell still plays.

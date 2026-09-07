# Assisted Coaching — UX brief

Working document for the post-MVP **assisted coaching** feature: an audio coach that calls
combinations over the top of the round timer. Captures the UX decisions taken on 2026-08-25 so the
screen-design and script-authoring stages have a fixed target. Not a spec — OpenSpec change
proposals derive from this.

Pipeline: **UX direction (this doc) → screen mockups (Open Design) → coach scripts → OpenSpec change.**

## Scope of v1

- Levels: **Beginner only**. Intermediate / Advanced are designed-for but not authored.
- Beginner vocabulary: punches **1, 2, 3** (jab, cross, lead hook) + footwork + coach filler.
- Available on **Shadow Boxing and Heavy Bag only** — the other three `WorkoutType` cases offer no
  coaching. Scripts differ between the two (see "Script content" below); this is real content
  divergence, not a reskin.
- Multi-round workouts are fully supported — every round gets a freshly drawn call sequence.
- User picks **numbering** ("one, two, three") or **named** ("jab, cross, hook") convention.

## Decision 1 — Coaching tracks are phrase clips driven by arc-segmented pools

One clip = **one complete call** (`"one-two-three, pivot left"`), not one word. Word-level clips were
rejected: a beginner combo is a single rhythmic burst, and stitching words destroys the cadence the
feature exists to teach. Pre-rendered whole-round tapes were rejected for locking rounds to
canonical lengths and giving no variety across a 12-round workout.

A script divides the round into four segments with their own weighted pool and cadence:

```
beginner_shadow.json
  segments:
    open   { share: 0.20, cadence: 8-10s, pool: [single_jab, double_jab, ...] }
    build  { share: 0.35, cadence: 6-8s,  pool: [one_two, one_two_three, ...] }
    work   { share: 0.30, cadence: 5-6s,  pool: [one_two_three_pivot, ...] }
    finish { share: 0.15, cadence: 4-5s,  pool: [burnout_1_2, hands_up, ...] }

clips/numbers/one_two_three_pivot.m4a
clips/names/one_two_three_pivot.m4a
```

Consequences:

- Segments are **proportional shares**, so a script works at any round length.
- Naming convention selects between two parallel clip folders keyed by the same phrase IDs — the
  script is convention-agnostic.
- **Determinism is preserved.** Seed the pool RNG from `(configID, roundIndex)`: rounds vary from
  each other, but a given workout replays identically. A full coached workout stays assertable
  against `FakeTimeSource` in microseconds, per guide §14.
- Coaching cues schedule against the **same monotonic deadline clock** as existing `AudioCue`s — a
  new cue kind on the existing engine, never a second competing timeline.

## Decision 2 — Coaching is a `Configuration` field with a ready-screen shortcut

Stored on `Configuration` (persists, badges `ConfigCard`, edited in `ConfigEditorView` via a
Coaching section that appears only for Shadow Boxing / Heavy Bag) **and** surfaced as a
`Coach: Off ▾` chip on the idle workout screen that edits that same field.

Two entry points into one stored value — a shortcut, not a duplicate. A separate "Coached" catalog
tab was considered and deferred: it needs a catalog to browse, and with Beginner alone it is a shelf
with one book on it. Revisit when level 2 exists.

Rejected outright: coached variants inside `WorkoutType`. That enum is load-bearing across
auto-naming, the session model, and the chart legend — adding a mode flag would reopen four shipped
specs.

## Decision 3 — Dual-convention call ticker on the running screen

```
        ( 02:14 )        <- ring, unchanged
         ROUND 3

       1  ·  2  ·  3
   JAB  CROSS  HOOK       <- fades out, next fades in
         pivot left

     [||]   [reset]
```

Numbers small above names large, under the ring, fading as the next call arrives. The ring stays
hero — the time is what people glance for.

Showing **both** conventions simultaneously is deliberate: the audio still forks by user preference,
but the screen teaches the number↔name mapping passively over a few sessions rather than leaving the
user to learn across a fork. It also provides the deaf/HoH path that audio-only would not.

A subtle ring pulse on each call is a nice-to-have accompaniment. A "Minimal screen" toggle that
suppresses the ticker entirely should exist for eyes-free purists.

## Decision 4 — Naming convention lives in `SettingsStore`

It is a preference about the *user*, not about a workout, and nobody flips it per-config. Store it
globally alongside `WarningSound` / `CountDirection` / `ColorSchemePreference` — a straight reuse of
the change-#9 pattern. Surface the control **in the coaching sheet** (discoverable at the point of
relevance) and mirror a row in Settings. One stored value, two places to set it.

## Decision 5 — Mock everything unlocked; keep the paywall seam

v1 screens assume **fully unlocked** coaching. No paywall UI is designed or built yet.

Still add an `EntitlementStore` protocol seam (constructor-injected, returns `true`) so a future
paywall is a composition-root change rather than a refactor — guide §5. Two constraints to carry
into the spec whenever monetisation does land:

1. **The entitlement gates only whether the coaching cue stream is scheduled.** Nothing else.
2. **The lock must never touch the workout clock.** A paywall that could stall or corrupt a round
   would violate the top ProRounds invariant. Non-negotiable.

For reference, the leading candidate when it does land: one-time StoreKit 2 non-consumable
(`Transaction.currentEntitlements` needs no backend, survives reinstall — respects local-first),
with the first round of any coached workout playing free so the coach is heard before the ask.

## Script content — direction for the authoring stage

- **Punches** — Beginner capped at 1/2/3 (jab, cross, lead hook). 4–6 unlock at Intermediate.
- **Footwork** — step in/out, circle left/right, pivot, angle off, on your toes.
- **Coach filler** — "hands up", "breathe", "reset", "last ten", "work!"
- **Arc** — Open (single shots, find range) → Build (2–3 punch combos + movement) → Work (faster
  cadence, combos into footwork) → Finish (burnout, last 20–30s).
- **Shadow vs Bag** — Shadow: angles, imaginary opponent, resetting stance, defence between combos,
  constant movement. Bag: planting the feet, hitting *through* the target, staying in range, body
  shots, controlling the swing — and a **longer cadence**, because you are recovering the bag
  between calls.

## Mockup-stage answers (settled 2026-09-07)

Mocked up in [`mockups/coaching.html`](mockups/coaching.html) — section A draws the coached flow
(7 screens) as chosen below; section B keeps every rejected variant with its trade-off.

- **Coach chip placement → a pill above the transport controls.** It reads as a setting for the run
  you are about to start and sits where the thumb already is; it costs ~50pt of vertical space and
  disappears once the workout starts. Rejected: the header row (too far from the thumb, level text
  strains at 12.5pt) and an inline segmented toggle (breaks the moment level 2 exists).
- **`ConfigCard` badge → names the level** ("Beginner"), not a bare coached/not marker. The badge is
  the one place the catalog says what kind of session this is, and it is already right when a second
  level lands. Constraint for the build: on narrow phones the badge **wraps below the round summary**
  rather than truncating it.
- **Ticker scale → compact, 24pt names / 13pt numbers / 14pt modifier.** Keeps the block two lines
  tall even for a four-punch call, so Intermediate does not force a redesign. **Verify legibility at
  true arm's length on device** before the ticker is spec'd — the mockup is drawn at phone width but
  read at desk distance. Rejected: 30pt (wraps a four-punch call, rivals the numeral) and the
  outgoing-ghost variant (a second block of moving text beside the hero).
- **"Minimal screen" → a global `SettingsStore` preference**, surfaced in the coaching sheet and
  mirrored in Settings, exactly like call style (Decision 4). No third coaching field on
  `Configuration`, no migration.

## Script stage (authored 2026-09-07)

Scripts live in [`coaching/`](coaching) — `phrases.json` (89 phrases), `beginner_shadow.json`,
`beginner_bag.json`, and `scripts/coach-script.py` (validator + round previewer + the reference
implementation of the selection algorithm). Read [`coaching/README.md`](coaching/README.md) before
the OpenSpec change: it carries the format, the guards, and the algorithm Swift must reproduce
byte for byte.

Decision 1 gains a detail the brief did not anticipate: a round is **five kinds of call**
(combo · defence · movement · technique · effort), not combos plus filler. Technique cues —
"hand back high", "chin down", "head off the centre line", "roll from the legs" — carry the coaching
value, and a `follows` tag lets them *answer* the call before them rather than fire at random.
Delivered mix is roughly 55% combo, 13% defence, 7% movement, 18% technique, 7% effort.

Still open: crossfade timing against real audio (~220ms assumed), `estMs` values must be replaced
with measured clip durations before the end-of-round guard can be trusted, and rest/prep stay silent
in v1.

## Next: audio, then OpenSpec (planned 2026-09-07)

**Audio — ElevenLabs.** TTS for the 115 coach clips (2,489 characters in total, so regenerating the
whole set after a wording change is cheap), and text-to-sound-effects to replace the five synthesized
placeholders in `Sources/ProRoundsFoundationAudio/Resources/`. Audition voices through the
`elevenlabs` MCP first — one voice must carry a fast combo, a technique correction, and a bark — then
set `COACH_VOICE_ID` and run [`../scripts/gen-coach-clips.py`](../scripts/gen-coach-clips.py). That
script measures each clip and writes the real duration back into `phrases.json`, replacing the hand
estimates the end-of-round guard depends on. Re-run `coach-script.py validate` afterwards: real
durations can breach a cadence ceiling. Shipping generated audio in an App Store build is commercial
use — confirm the plan tier before recording day.

**Then three OpenSpec changes**, bottom-up, one at a time:

| | Change | Scope | Needs clips |
|---|--------|-------|-------------|
| 1 | `coaching-engine` | `ProRoundsFoundationCoaching`: phrase catalog, script loading, `CoachCueScheduler`. Pure logic, test-first against `coach-script.py preview` fixtures. | No |
| 2 | `coaching-config` | `Configuration` coaching field + migration, `SettingsStore` call style + ticker visibility, editor section, `ConfigCard` badge, `EntitlementStore` seam. | No |
| 3 | `coached-workout` | Coaching cues as a new kind on the existing `AudioCuePlayer`, the ticker, minimal screen, the `Coach ▾` chip and sheet. | Yes |

Replacing the five workout sound effects is a separate small change against the existing assets.

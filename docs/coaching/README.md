# Coach scripts — Beginner

Authoring source for the **assisted coaching** feature (see [`../COACHING_UX_BRIEF.md`](../COACHING_UX_BRIEF.md)).
These files are content, not code: they define *what* the coach says and *how it is paced*. The
Swift scheduler that plays them is spec'd in the OpenSpec change that follows this stage.

| File | What it is |
|------|------------|
| `phrases.json` | The phrase catalog — every call the beginner coach can make, its text, tags and clip kind. **Single source of truth for IDs.** |
| `beginner_shadow.json` | Shadow Boxing script: arc segments, cadence, and the weighted pools drawn from the catalog. |
| `beginner_bag.json` | Heavy Bag script. Slower cadence throughout, plus bag-specific calls and corrections. |
| `../../scripts/coach-script.py` | Validator, round previewer, and the **reference implementation** of the selection algorithm. |

```sh
scripts/coach-script.py validate                                   # cross-references, pool health, guards
scripts/coach-script.py preview beginner_shadow --convention names # hear a round on paper
scripts/coach-script.py stats  beginner_bag --rounds 24            # delivered mix + phrase coverage
```

## The five kinds of call

A round is not a stream of combinations. It is five kinds of call interleaved, and the mix is what
makes it sound like a coach watching you rather than a list being read out:

| Kind | What it does | Example |
|------|--------------|---------|
| `combo` | Punches to throw | *"One, two, three — pivot left"* |
| `defence` | Catching, slipping, rolling — with or without a counter | *"Roll left — two, three"* |
| `movement` | Feet only | *"Angle off — do not stand in front of them"* |
| `technique` | A correction. **The coaching value lives here.** | *"Don't leave that jab hanging — snap it back"* |
| `effort` | Push, and the round's shape | *"Hands stay up — push through it"* |

Roughly **55% combo · 13% defence · 7% movement · 18% technique · 7% effort** is delivered per round;
`stats` prints the real numbers.

## Technique cues answer the call before them

A `technique` phrase may declare `follows: [tags]` — it is only eligible when the previous call
carried one of those tags. This is what turns a reminder into a correction:

```
  Roll left                          (defence,   tags: [roll])
  Roll from the legs, not the waist  (technique, follows: [roll])
```

Two rules drive it. After a **combo**, a matching cue is weighted `followsBoost` (×3) against the
generic pool, so *"one, two"* is often — not always — followed by *"lead hand straight back to your cheek"*.
After a **defence or movement** call, `answerAfterNonCombo` restricts the pool to matching cues
entirely, so defence is always corrected rather than merely acknowledged.

> This rule is load-bearing. Under an earlier draft that forced a combo after every non-combo call,
> seven authored cues (`tech_roll_from_the_legs`, `tech_catch_dont_swat`, `tech_slip_small`,
> `tech_eyes_up_defending`, `tech_guard_stays_home`, `tech_answer_after_defence`,
> `tech_bag_body_dig`) could **never fire** — no combo carries a `slip`/`roll`/`catch` tag.
> `validate` now fails on a cue whose `follows` tags nothing in the same script produces.

## Voice

A corner talks; it does not narrate. Three rules, applied across the catalog:

- **Contractions.** "Don't leave that jab hanging", never "Do not get lazy with that jab hand".
- **Name the direction, not the abstraction.** There is no "it" to roll under — not in shadow, and
  not on the bag either, where people roll *in front of* the bag rather than timing its swing. The
  call is **"Roll left"** / **"Roll right"**, which is what a coach actually shouts. Both scripts use
  the same directional rolls.
- **Cut the explanation.** "Angle off", not "Angle off — do not stand in front of them". The cue is a
  reminder of something already taught, not the teaching itself.

## Recording the clips

**Voice: "Coach Stokes"** (ElevenLabs voice library, `YifVBvyYTdmecR2h3t20`), chosen at audition over
29 other candidates — the premade catalogue plus 27 library coach/trainer/sergeant voices. The ID is
baked into `scripts/gen-coach-clips.py`; `$COACH_VOICE_ID` overrides it to re-audition. **One voice
speaks every clip in both conventions**, or the app sounds like two different coaches.

```bash
export ELEVENLABS_API_KEY=...            # a paid key: free plans cannot use library voices via the API
./scripts/gen-coach-clips.py --dry-run   # what would be generated, and the character cost
./scripts/gen-coach-clips.py             # generate whatever is missing
./scripts/gen-coach-clips.py --force     # regenerate everything, after a wording change
./scripts/gen-coach-clips.py --measure   # no API calls: rewrite estMs from the clips on disk
```

Clips land in `Sources/ProRoundsFoundationCoaching/Resources/clips/` in the `numbers/` `names/`
`shared/` layout above. The whole catalog is only 2,489 characters, so regenerating the set after a
wording change is cheap — treat the clips as derived artefacts, not hand-tuned assets.

**Trailing silence is trimmed.** ElevenLabs pads roughly 330ms of silence onto every clip; measured
across the audition set, 28% of the returned audio was silence. That padding is dead cadence space
the scheduler would otherwise reserve, so `trim_silence()` cuts each clip to speech plus `TAIL_PAD_MS`
(80ms — enough decay that plosive endings like "Work!" do not sound clipped) before the AAC encode.

**Licensing.** ElevenLabs free plans are non-commercial *and* cannot speak voice-library voices
through the API at all. Clips that ship must be generated under a paid plan; Starter is enough for
library voices flagged `free_users_allowed`, Creator for the rest.

## Shadow vs bag

Not a reskin — the scripts diverge on content, as the brief requires:

- **Cadence.** Bag runs 10–12s in the open down to 5–6s in the finish; shadow runs 8–10s down to
  4–5s. You are recovering the bag between calls.
- **Defence.** Rolling and slipping are identical in both — same directional calls. What the bag
  drops is **catching**: nothing is punching at you, so *"Catch the jab"* and *"Catch — jab, cross"*
  are shadow-only. Earlier drafts gave the bag swing-timing calls; that was wrong for how most people
  actually work a bag.
- **Technique.** Bag adds planting the feet, punching *through* the target, staying in range, not
  leaning on it, digging under the elbow. Shadow adds angles, not standing square, resetting stance.

### Lead hand and rear hand are different faults

They fail in different ways, so they are different cues with different `follows` tags:

| Cue | Fires after | Fault it corrects |
|-----|-------------|-------------------|
| `tech_lead_hand_back` — *"Lead hand straight back to your cheek"* | `jab` | The jab hand returns low or wide |
| `tech_rear_hand_stays` — *"Don't drop that rear hand when you jab"* | `jab` | The rear hand drops while the lead works |
| `tech_rear_hand_back` — *"Rear hand back to your chin"* | `cross` | The cross is left hanging out there |
| `tech_rear_hand_chin` — *"Rear hand glued to your chin"* | anything | Standing guard, not a return |
| `tech_lazy_hand` — *"Snap that jab back — don't leave it out there"* | `jab` | Slow return, as opposed to a low one |

## Format

### `phrases.json`

```jsonc
{ "id": "jab_cross_hook_pivot",
  "kind": "combo",
  "clip": "forked",                       // forked → clips/numbers/<id>.m4a + clips/names/<id>.m4a
  "tags": ["jab","cross","hook","movement"],
  "estMs": 2000,                          // spoken length; drives gap and end-of-round guards
  "text":   { "numbers": "One, two, three — pivot left", "names": "Jab, cross, hook — pivot left" },
  "ticker": { "numbers": "1 · 2 · 3", "names": "Jab Cross Hook", "modifier": "pivot left" } }

{ "id": "tech_roll_from_the_legs",
  "kind": "technique",
  "clip": "shared",                       // shared → clips/shared/<id>.m4a, one recording
  "tags": ["defence","roll"],
  "follows": ["roll"],
  "estMs": 2100,
  "text": "Roll from the legs, not the waist",
  "ticker": { "line": "Roll from the legs" } }
```

`windowFromRoundEndMs: [lo, hi]` restricts a phrase to a slot with that much round remaining —
*"Last ten"* is only honest between 8s and 12s left.

**Recording budget:** only phrases that name punches by number fork into two conventions. 26 forked
phrases (52 clips) + 63 shared = **115 clips**, not 178. Convention forking is a property of
the phrase, not the folder.

### Ticker rendering

Per the mockups, a coached running screen shows numbers small above names large:

- `combo` / `defence` with punches → `ticker.numbers` row, `ticker.names` row, optional
  `ticker.modifier` line.
- everything else → `ticker.line` alone, in the names slot, no numbers row.

### Script files

`voice` and `intent` are **author notes, never spoken** — they describe what a segment is for so the
next script (Intermediate, or a new workout type) is written to the same shape. Only `text` in
`phrases.json` is ever heard.

```jsonc
{ "id": "beginner_shadow", "workoutType": "shadowBoxing",
  "guards": {
    "roundStartDelayMs": 1500,     // let the round-start bell breathe
    "roundEndGuardMs":   2000,     // no call may still be speaking at the bell
    "warningGuardMs":     750,     // keep clear of the round-end warning cue
    "minGapMs":          1200,     // silence between the end of one call and the start of the next
    "noRepeatWithinKind": { "combo": 5, "defence": 4, "movement": 2, "technique": 6, "effort": 3 },
    "maxConsecutiveNonCombo": 2,   // never three calls running without punches
    "followsBoost": 3,
    "answerAfterNonCombo": true
  },
  "segments": [
    { "id": "open", "share": 0.20, "cadenceMs": [8000, 10000],
      "mix":   { "combo": 0.40, "defence": 0.10, "movement": 0.13, "technique": 0.37, "effort": 0.00 },
      "pools": { "combo": [ { "id": "jab", "w": 6 }, … ], … },
      "pinned": [ { "id": "effort_last_ten", "atFromRoundEndMs": 10000 } ] } ] }
```

- **`share`** — proportional, so one script works at any round length. Shares sum to 1.
- **`cadenceMs`** — call start to call start, drawn uniformly. The real gap is
  `max(drawn, estMs + minGapMs)`.
- **`mix`** — a **draw weight, not the delivered share.** Adjacency rules convert some draws to
  combos, so delivered non-combo shares run ~30% below the declared mix. Tune against `stats`.
- **`noRepeatWithinKind`** — counted **per kind**: a technique cue waits for 6 other *technique*
  cues, not 6 calls. Counting across all calls let the same reminder land three times a round.
  `validate` fails if a window is as large as a pool it applies to.
- **`pinned`** — placed before anything is drawn; drawn calls flow around them. Dropped silently if
  the round is too short for the cue to be honest.

## Selection algorithm (what Swift must reproduce)

`scripts/coach-script.py preview` is the reference. The Swift `CoachCueScheduler` must produce
byte-identical sequences, so its tests can use previews as fixtures.

1. **Seed** — FNV-1a 64 over `"<configID>#<roundIndex>"`, then **SplitMix64**. Not
   `SystemRandomNumberGenerator`: the sequence must be stable across OS versions and machines.
   Rounds differ from each other; a given workout replays identically (brief, Decision 1).
2. Place `pinned` calls; reserve `minGapMs` either side.
3. Per segment, walk `t` from the segment start: draw a kind by `mix`; force `combo` if the drawn
   kind equals the previous kind or would be a third non-combo in a row.
4. Filter the pool: per-kind no-repeat, `follows` against the previous call's tags,
   `windowFromRoundEndMs`. Apply `followsBoost` / `answerAfterNonCombo`. Fall back to the combo pool
   if nothing survives.
5. Draw weighted, nudge clear of the warning cue and any pinned window, and **drop the call** if it
   would still be speaking at `roundEndGuardMs`.
6. Advance `t` by `max(drawn cadence, estMs + minGapMs)`.

**Invariants this must not touch.** Cues schedule against the same monotonic deadline clock as
existing `AudioCue`s — a new cue kind on the existing engine, never a second timeline. Coaching must
never move a phase boundary, change a round count, or delay the bell. It is an output of the clock,
not an input to it.

## Open for the OpenSpec stage

- **Rest and prep are silent in v1.** A rest coach ("breathe, thirty seconds") and a prep call-in are
  cheap to add later; neither is authored here.
- **Crossfade between calls** is assumed ~220ms in the mockups; it needs to be felt against real
  audio before it is spec'd.
- ~~**`estMs` values are estimates.**~~ **Resolved.** Every `estMs` is now the measured duration of
  the real trimmed clip, written back by `gen-coach-clips.py`. Re-run `coach-script.py validate` after
  any regeneration: real durations can breach a cadence ceiling the estimates cleared.
- **Intermediate / Advanced** are not authored. Adding punches 4–6 means new phrase IDs and new
  pools, not a format change.

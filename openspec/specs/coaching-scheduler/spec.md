# coaching-scheduler Specification

## Purpose
Defines which coaching call is made, and when, within a single round.

The scheduler is an **output** of the round timer, never an input: it takes no clock, holds no
state, and returns offsets rather than deadlines, so coaching cannot move a phase boundary, change a
round count, or delay the bell. Given a script, a configuration id, a round index and a round
length, it returns the same schedule every time — which is what lets a workout replay identically
and lets an entire round be verified in microseconds against a committed fixture.

`scripts/coach-script.py` is normative for this capability. Where its behaviour and the prose
disagree, the Python wins and the prose is corrected.

## Requirements
### Requirement: Scheduling a round is pure and deterministic
The system SHALL produce a round's cue schedule from a script, a `configID`, a `roundIndex`, and a
round length alone. The scheduler SHALL NOT read a clock, perform I/O, or mutate shared state.

#### Scenario: Same inputs produce the same schedule
- **WHEN** the same script, `configID`, `roundIndex` and round length are scheduled twice
- **THEN** both runs SHALL return an identical ordered sequence of cues with identical offsets

#### Scenario: A workout replays identically
- **WHEN** a configuration is run again with the same rounds
- **THEN** each round SHALL reproduce the calls it made before

#### Scenario: Rounds differ from one another
- **WHEN** consecutive rounds of one configuration are scheduled
- **THEN** their sequences SHALL differ

#### Scenario: Matches the Python reference byte for byte
- **WHEN** a round is scheduled with the same inputs as `scripts/coach-script.py preview`
- **THEN** the phrase ids and offsets SHALL equal the reference output, verified against committed
  fixtures covering both scripts and a range of round lengths

### Requirement: Segments are placed proportionally so any round length works
The system SHALL divide the round into its script's segments by proportional share, so a script
authored once serves any round length.

#### Scenario: Shares map onto the round
- **WHEN** a round of any length is scheduled
- **THEN** each segment SHALL occupy its declared share of the round, in order

#### Scenario: Cadence is drawn within the segment range
- **WHEN** the scheduler advances within a segment
- **THEN** the interval from one call's start to the next SHALL be drawn uniformly from the segment's
  `cadenceMs`, then widened to at least `estMs + minGapMs`

### Requirement: Adjacency rules keep punches in the round
The system SHALL apply the script's adjacency rules when choosing a kind, so the coach never stalls
into consecutive non-punching calls.

#### Scenario: A repeated kind becomes a combo
- **WHEN** the drawn kind equals the previous call's kind
- **THEN** the kind SHALL be forced to combo

#### Scenario: Never three non-combos in a row
- **WHEN** the previous two drawn calls were both non-combo
- **THEN** the next drawn call SHALL be a combo. This governs the **drawn** sequence; the delivered
  sequence may still show a longer run in two cases, both reference behaviour — a pinned cue, which
  is placed before the walk and never counted by it, or two calls sharing an offset, where the
  `(offset, id, kind)` sort orders by phrase id rather than by draw order

#### Scenario: A technique cue can answer the call before it
- **WHEN** a candidate declares `follows` tags matching the previous call's tags
- **THEN** its draw weight SHALL be multiplied by `followsBoost`

### Requirement: No-repeat windows are counted per kind
The system SHALL enforce each per-kind no-repeat window against other calls of that same kind, not
against all calls.

#### Scenario: A technique cue waits for other technique cues
- **WHEN** the technique window is 6
- **THEN** a technique phrase SHALL NOT recur until 6 other technique cues have been delivered

#### Scenario: Falls back to combos when nothing survives
- **WHEN** filtering leaves no eligible candidate in the drawn kind's pool
- **THEN** the scheduler SHALL fall back to the combo pool rather than emit nothing

### Requirement: Pinned cues are placed before anything is drawn
The system SHALL place a segment's pinned cues first, at their declared offset from the round end,
and flow drawn calls around them.

#### Scenario: A pinned cue lands at its offset
- **WHEN** a segment pins a cue at a given distance from the round end
- **THEN** that cue SHALL appear at that offset and `minGapMs` SHALL be reserved either side

#### Scenario: A pinned cue is dropped when the round is too short
- **WHEN** the round is too short for a pinned cue to be honest
- **THEN** that cue SHALL be omitted silently rather than distort the schedule

### Requirement: No call is still speaking at the bell
The system SHALL drop any call whose measured `estMs` would leave it still speaking inside
`roundEndGuardMs`, and SHALL keep calls clear of the round-end warning cue.

#### Scenario: A call that would overrun the bell is dropped
- **WHEN** a candidate's start offset plus its `estMs` falls inside the end-of-round guard
- **THEN** that call SHALL be dropped rather than truncated or shifted past the bell

#### Scenario: Calls avoid the warning cue
- **WHEN** a call would start within `warningGuardMs` of the round-end warning
- **THEN** it SHALL be nudged clear, or dropped if it cannot be

#### Scenario: The round opens with silence
- **WHEN** a round begins
- **THEN** no drawn call SHALL start before `roundStartDelayMs`, so the round-start bell is not
  spoken over. The delay gates the **first segment only** — later segments begin at their own
  boundary — and pinned cues are placed before the walk and do not consult it at all. With the
  shipped scripts the earliest call observed across 240 round lengths is exactly `roundStartDelayMs`

### Requirement: Coaching never influences the workout clock
The scheduler SHALL be an output of the round timer, never an input to it. Coaching SHALL NOT move a
phase boundary, change a round count, or delay the bell.

#### Scenario: Schedule is bounded by the round it was given
- **WHEN** a round of a given length is scheduled
- **THEN** every returned cue offset SHALL fall inside that round, and the scheduler SHALL expose no
  means of extending it

#### Scenario: An empty schedule is valid
- **WHEN** a round is too short to fit any call after guards are applied
- **THEN** the scheduler SHALL return an empty schedule and the round SHALL run normally


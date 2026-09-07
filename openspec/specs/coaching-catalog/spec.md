# coaching-catalog Specification

## Purpose
Defines how the authored coaching content — the phrase catalog and the per-workout scripts —
becomes typed, validated domain values that the rest of the app can rely on.

Phrase ids are the single source of truth: nothing in Swift inlines call text, and a script names
ids rather than words. The integrity rules here run at load, mirroring
`scripts/coach-script.py validate`, so an authoring mistake fails immediately rather than reaching
the scheduler and producing a subtly wrong workout. Author notes carried in the JSON are never
decoded, which makes speaking one structurally impossible rather than merely discouraged.

## Requirements
### Requirement: Phrase catalog decodes into typed domain values
The system SHALL decode `phrases.json` into value types carrying each phrase's id, kind, clip kind,
tags, measured `estMs`, spoken text, and ticker text. Phrase ids SHALL be the single source of truth;
no call text may be inlined in Swift.

#### Scenario: Forked and shared phrases decode to their clip shapes
- **WHEN** the catalog is decoded
- **THEN** a phrase marked `forked` SHALL carry distinct `numbers` and `names` text, and a phrase
  marked `shared` SHALL carry one text used by both conventions

#### Scenario: Every phrase declares a known kind
- **WHEN** the catalog is decoded
- **THEN** every phrase's kind SHALL be one of combo, defence, movement, technique, or effort, and an
  unrecognised kind SHALL fail decoding rather than be silently dropped

#### Scenario: Catalog is loaded from the package bundle
- **WHEN** the catalog is requested at runtime
- **THEN** it SHALL be read from the module's own resource bundle, with no filesystem path assumption
  and no network access

#### Scenario: Malformed catalog fails loudly
- **WHEN** the catalog is missing a required field or contains invalid JSON
- **THEN** loading SHALL throw a typed error naming the offending phrase id where one is known

### Requirement: Script files decode with their segments and guards
The system SHALL decode a script file into its workout type, guard values, and ordered segments, each
segment carrying its share, cadence range, kind mix, per-kind pools with weights, and any pinned cues.

#### Scenario: Segment shares are proportional
- **WHEN** a script is decoded
- **THEN** its segment shares SHALL sum to 1 within a small tolerance, and decoding SHALL fail if they
  do not

#### Scenario: Author notes are not spoken
- **WHEN** a script carries `voice` or `intent` fields on a segment
- **THEN** those SHALL be treated as author notes and never surfaced as speakable text

#### Scenario: Both beginner scripts load
- **WHEN** the catalog and scripts are loaded
- **THEN** `beginner_shadow` and `beginner_bag` SHALL both decode, and each SHALL resolve every pool
  entry to a phrase that exists in the catalog

### Requirement: Catalog integrity is validated at load
The system SHALL enforce, at load time, the same integrity rules `scripts/coach-script.py validate`
enforces, so an authoring error cannot reach the scheduler.

#### Scenario: Unknown phrase id in a pool is rejected
- **WHEN** a script pool references a phrase id absent from the catalog
- **THEN** validation SHALL fail and name the offending id

#### Scenario: A no-repeat window cannot exceed its pool
- **WHEN** a per-kind no-repeat window is as large as the pool it applies to
- **THEN** validation SHALL fail, because the window could never be satisfied

#### Scenario: A follows tag must be answerable
- **WHEN** a cue declares a `follows` tag that nothing in the same script produces
- **THEN** validation SHALL fail

#### Scenario: Every phrase has a clip
- **WHEN** the catalog is validated
- **THEN** every phrase SHALL resolve to its clip file or files in the resource bundle — `numbers/`
  and `names/` for a forked phrase, `shared/` for a shared one

### Requirement: Clip resolution honours the naming convention
The system SHALL resolve a phrase id plus a naming convention to exactly one clip resource.

#### Scenario: Forked phrase resolves per convention
- **WHEN** a forked phrase is resolved under the numbers convention
- **THEN** the `numbers/` clip SHALL be returned, and under the names convention the `names/` clip

#### Scenario: Shared phrase ignores convention
- **WHEN** a shared phrase is resolved under either convention
- **THEN** the same `shared/` clip SHALL be returned


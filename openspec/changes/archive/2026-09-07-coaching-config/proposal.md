## Why

`ProRoundsFoundationCoaching` ships a working catalog and scheduler, and **nothing links it**. There
is no way to say "coach this workout", no way to choose whether the coach calls "One, two" or "Jab,
cross", and no seam for the paywall that will eventually gate it.

That is the whole of this change: make coaching *configurable and reachable*. It stops short of
playing anything. Keeping storage and settings separate from playback means the migration — the one
genuinely irreversible step, since it rewrites the user's stored configurations — lands on its own,
against a suite that can prove old records survive it, rather than buried in a change that also
touches `AVAudioSession` and the running screen.

## What Changes

- **`Configuration` gains a coaching field.** A `CoachingLevel?` (nil = off; `.beginner` the only
  case in v1), on the domain type in `ProRoundsDataConfig`.
- **The first SwiftData migration.** The store has never versioned its schema; adding a field to
  `ConfigurationEntity` forces the question. Existing configurations must survive with coaching off.
- **`ConfigurationValidator` covers the new field** — coaching is only offered for the two workout
  types with authored scripts, so a configuration claiming coaching on Skipping is invalid.
- **`SettingsStore` gains two person-level preferences:** the naming convention (numbers vs names)
  and the "minimal screen" preference. Both are about the user, not the workout — nobody flips them
  per-config.
- **Config editor gains a Coaching section**, shown only for Shadow Boxing and Heavy Bag; the
  Settings screen mirrors the two new preferences.
- **`ConfigCard` gains a badge** naming the coaching level.
- **An `EntitlementStore` protocol seam**, constructor-injected, returning unlocked. No paywall UI.
- **The app finally links `ProRoundsFoundationCoaching`** — `project.yml` gains the product and the
  composition root wires the new store.
- **No** audio, cue playback, ticker, coaching sheet on the running screen, or `Coach: Off ▾` chip.
  Those are change 3 (`coached-workout`).

## Capabilities

### New Capabilities
- `entitlement-seam`: the protocol boundary a future paywall plugs into, and the two constraints it
  must always honour.

The coaching preferences deliberately do **not** get a capability of their own. Decision 4 puts them
in the existing `SettingsStore` alongside warning sound, count direction and appearance — "a straight
reuse of the change-#9 pattern" — so they belong as requirements on `settings-store`, not in a
parallel spec that would fragment one store across two contracts.

### Modified Capabilities
- `workout-configuration`: `Configuration` carries a coaching level, and the derived values
  (auto-name, total duration) are explicitly unaffected by it.
- `configuration-repository`: the entity gains a coaching column and the store gains its first
  schema migration; existing records must round-trip with coaching off.
- `configuration-validation`: coaching is valid only for workout types with an authored script.
- `settings-store`: two new preferences alongside warning sound, count direction and appearance.
- `config-editor`: a Coaching section, conditional on workout type.
- `config-list`: `ConfigCard` badges the coaching level.
- `settings-screen`: rows for the two new preferences.
- `app-composition`: the composition root constructs and injects the entitlement store.

## Impact

- **Data:** `Sources/ProRoundsDataConfig/{Configuration,ConfigurationEntity,ConfigurationMapper,
  ConfigurationValidator}.swift`; `Sources/ProRoundsDataSettings/SettingsStore.swift` (protocol +
  both implementations + the in-memory fake).
- **Presentation:** `ProRoundsFeatureConfig` (editor section + list badge), `ProRoundsFeatureSettings`
  (two rows), `ProRoundsDesignSystem/ConfigCard.swift`.
- **Wiring:** `project.yml` links `ProRoundsFoundationCoaching`; `ProRounds/AppEnvironment.swift`
  constructs the `EntitlementStore`.
- **Migration risk — the real one in this change.** SwiftData is the user's only copy of their
  configurations; there is no backend and no export. A migration that drops records loses data
  permanently. Adding an attribute that is optional (or defaulted) keeps this in lightweight-migration
  territory, and the tests must prove a pre-change store opens and round-trips.
- **Untouched invariants:** no network, no PII, no change to the timer engine, phase sequencing or
  bell timing. The entitlement gates only whether cues are scheduled and must never reach the clock.
- **Not blocked by clips:** the 115 recordings matter only in change 3.

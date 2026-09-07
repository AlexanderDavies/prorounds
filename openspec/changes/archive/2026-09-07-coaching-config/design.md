## Context

`ProRoundsFoundationCoaching` is built, tested and archived, and nothing links it. This change makes
coaching selectable and remembered.

One part of it is irreversible in a way nothing before it has been. SwiftData is the **only** copy of
the user's configurations — local-first, no backend, no export — and the store has never been
versioned: there is no `VersionedSchema` or `SchemaMigrationPlan` anywhere in the repo. Adding a
column to `ConfigurationEntity` is therefore the first migration the app has ever performed, and a
migration that drops records loses them permanently. That single fact drives most of the decisions
below.

The rest is settled by the UX brief: coaching is a `Configuration` field (Decision 2), the naming
convention is a `SettingsStore` preference (Decision 4), and the entitlement is a seam with nothing
behind it yet (Decision 5).

## Goals / Non-Goals

**Goals:**
- Store a coaching level per configuration and migrate existing stores without losing a record.
- Put the two person-level preferences in the existing `SettingsStore`, following the pattern
  already shipped for warning sound, count direction and appearance.
- Make coaching selectable where it is available and impossible to select where it is not.
- Land the entitlement seam so a paywall is later a composition-root change.

**Non-Goals:**
- Playing a coaching cue, the ticker, the coaching sheet, or the `Coach: Off ▾` chip on the running
  screen — all change 3.
- Any paywall UI, StoreKit dependency, or purchase flow.
- A coached-catalog tab. Deferred until a second level exists; with Beginner alone it is a shelf
  with one book on it.
- Levels beyond Beginner, or coaching for the three unscripted workout types.

## Decisions

**Model coaching as `CoachingLevel?` on `Configuration`, nil meaning off.** An optional rather than a
`.off` case, because "no coaching" is genuinely the absence of a choice rather than a kind of
coaching, and because it maps directly onto an optional column, which is what keeps the migration
lightweight. *Alternative considered:* a `Coaching` struct with a level and future per-config options
— rejected as speculative; there are no per-config options, and Decision 4 explicitly moves the one
candidate (naming convention) to settings.

**Keep coaching out of `WorkoutType`.** Rejected outright in the brief and worth restating: that
enumeration is load-bearing across auto-naming, the session model and the chart legend, so coached
variants would reopen four shipped specs. A test asserts the enumeration still has exactly its five
cases.

**Add the column as optional to stay in lightweight-migration territory.** SwiftData migrates
automatically when a new attribute is optional or defaulted; a non-optional attribute without a
default fails to open an existing store. Optional is the safer of the two because it needs no
agreement between the model default and what the migrator writes. *Alternative considered:* declaring
a `VersionedSchema` and a `SchemaMigrationPlan` now — rejected for this change: introducing a
versioning scheme is a larger commitment than the change needs, and a purely additive optional column
does not require it. **When a future change alters or removes a column, that is the moment to
introduce versioning, and it should be its own change.**

**Prove the migration against a real old store, not a mocked one.** A test writes a store using the
pre-change entity shape, closes it, reopens it with the new schema, and asserts every record is
present, reads back uncoached, and is still writable. A migration test that constructs its fixture
with the *new* model tests nothing. *This is the single most important test in the change.*

**Coaching validity is a validator rule, not a type constraint.** `Configuration` will happily hold
coaching for Skipping; `ConfigurationValidator` rejects it, and the editor clears it on a type
change. *Alternative considered:* making it unrepresentable by pairing level and workout type in one
type — rejected: it would complicate every construction site to prevent a state the existing
validate-before-save path already blocks, and the validator is where every other cross-field rule
lives.

**The entitlement returns a plain `Bool` synchronously.** No `async`, no `Result`, no publisher. The
seam must be impossible to await, because the constraint that matters is that it can never stall a
round. Making it synchronous and local is what enforces that structurally rather than by convention.

**The `SettingsStore` protocol gains two properties rather than a nested coaching type.** It is a
flat bag of preferences by design (guide §6.4), and both new values are independent scalars. Adding
them flat keeps the in-memory fake trivially constructible, which every feature test depends on.

## Risks / Trade-offs

- **The migration loses configurations.** The one genuinely destructive failure available in this
  change → optional column, real old-store round-trip test, and no other schema edit lands in the
  same change so the diff stays reviewable.
- **A user's coached configuration silently stops being coached** if a later change renames the
  stored level string → the raw value is stored, not the enum ordinal, and a test pins the exact
  persisted string so a rename fails loudly.
- **Editor clearing coaching on a workout-type change is data loss in miniature.** Someone switches
  type to look at something and their coaching choice is gone → the alternative (saving an invalid
  configuration, or blocking the type change) is worse; the clear is the least surprising, and it
  happens before save so cancelling still discards it.
- **The entitlement seam is dead code in v1.** Everything it gates is unlocked → it is a protocol and
  one implementation, small enough to be cheap, and Decision 5 makes retrofitting it later a refactor
  across features rather than a composition-root edit.
- **Coverage.** The gate is 90% and currently 92.58%; view code is excluded but view models are not,
  and this change adds mostly small branching code that is easy to leave untested → the editor's
  conditional section and the type-change clearing both need view-model tests, not just snapshots.

## Migration Plan

Additive and low-risk in the code, genuinely irreversible in the data. The column is optional, so an
old store opens under the new schema unchanged and every existing configuration reads back with
coaching off. There is no down-migration: a store opened by the new schema will carry the new column,
though an older build would ignore it rather than fail. Rollback of the *code* is safe; rollback
after a user has set a coaching level loses only that level.

## Open Questions

- **Does the minimal-screen preference belong in this change at all?** It is a settings value with no
  visible effect until change 3 builds the running screen. Landing it here keeps both coaching
  preferences together and lets the Settings screen ship complete; the cost is a preference that does
  nothing for one change. Kept here on those grounds, but it is the one item that could reasonably
  move.
- **What the badge says for a second level** is a design question that does not block: the badge
  carries the level's name, so a second level needs no redesign.

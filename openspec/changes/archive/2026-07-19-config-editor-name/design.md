## Context

The editor duplicates the name: a read-only auto-name preview row plus a separate "Custom name
(optional)" text field. Users can't tell which is authoritative. `changes.md` #4 chose the
placeholder-auto interaction: one field, auto-name as grey placeholder while blank.

## Goals / Non-Goals

- **Goals:** a single editable name field with a pencil affordance; auto-name shown as its placeholder;
  remove the read-only name preview row; keep the live Total preview.
- **Non-Goals:** no change to what is persisted (blank → `customName == nil` → auto-name at read time),
  validation, or the field ordering. No pre-filling the field with the effective name (rejected in
  favour of placeholder-auto so "blank = auto" stays obvious and the auto-name stays live).

## Decisions

### Placeholder is the auto-name (SwiftUI-native)

`TextField(model.autoName, text: $model.draft.name)` shows the auto-name in the placeholder role
(grey) exactly while `name` is empty — which is precisely the "blank = auto" behaviour. No custom
empty-state logic needed. A leading `pencil` glyph signals the field is editable.

### `autoName` factored onto the draft (single source)

`ConfigurationDraft.autoName` computes the auto-name from the current fields; `effectiveName` reuses it
(`trimmed.isEmpty ? autoName : trimmed`). The view model exposes `autoName` for the placeholder
(replacing the now-unused `previewName`). `build()` still maps a blank name to `customName == nil`, so
the persisted model is unchanged.

### Accessibility

The pencil is decorative (`accessibilityHidden`); the field is a combined element labelled "Name" with
its value being the custom name, or the auto-name when blank — so VoiceOver reads the effective name.

## Risks / Trade-offs

- **Placeholder legibility:** a placeholder is intentionally lower-contrast than entered text; that's
  the correct signal for "this is the default, not your input," and the auto-name remains readable.

## Migration Plan

Pure in-place UI change; no data migration. Update the editor view-model test and re-record the editor
snapshot in the same change set.

## Why

The editor shows **two** name things — a read-only "Name" preview row (the auto-generated name) *and*
a separate "Custom name (optional)" text field. It's confusing which one is "the name" and how they
relate. (From hands-on use — `changes.md` #4.)

## What Changes

- **One editable name field with a pencil affordance.** The separate read-only name-preview row is
  removed. The name field shows the live **auto-generated name as its placeholder** while the custom
  name is blank; typing sets the custom name, and clearing it reverts to the auto-name.
- **The live Total preview stays.** Only the name preview row is folded into the field.

## Capabilities

### Modified Capabilities
- `config-editor`: the auto-name previews inside the name field as its placeholder (no separate
  read-only name row); the live total preview is unchanged.

## Impact

- `ConfigEditorView` (collapse the preview row + custom-name field into one pencil field),
  `ConfigEditorViewModel` (`previewName` → `autoName` for the placeholder), `ConfigurationDraft`
  (factor out `autoName`, reused by `effectiveName`).
- Update the editor view-model test (placeholder auto-name; typing/clearing) and re-record the editor
  snapshot. No change to validation, persistence, or the saved model (`customName` is still nil when
  blank).

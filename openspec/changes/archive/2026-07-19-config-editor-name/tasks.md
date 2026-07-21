## 1. Draft & view model — expose the auto-name

- [x] 1.1 Factor `ConfigurationDraft.autoName` out of `effectiveName` (reused); expose `ConfigEditorViewModel.autoName`, replacing `previewName` (spec: config-editor)
- [x] 1.2 Update the editor view-model test: blank name ⇒ `autoName` is the live auto-name; typing sets the custom name; clearing reverts to the auto-name

## 2. View — single pencil name field

- [x] 2.1 Remove the read-only "Name" preview row; replace the custom-name field with one editable field (pencil glyph + `TextField(autoName, text:)` placeholder), keeping the live Total row (spec: config-editor)

## 3. Verification

- [x] 3.1 `./scripts/test.sh` + `./scripts/coverage.sh` green; `./scripts/lint.sh` strict clean
- [x] 3.2 Re-record the editor snapshot; review the single name field shows the auto-name placeholder + pencil and there's no separate name row
- [x] 3.3 `openspec validate config-editor-name` clean; README unaffected (behaviour, not build)

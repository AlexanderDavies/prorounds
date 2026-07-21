## 1. App icon (DESIGN §10)

- [x] 1.1 Add `scripts/gen-icon.swift` (SwiftUI → 1024 PNG) rendering the "Ring + PR" mark
- [x] 1.2 Create `ProRounds/Assets.xcassets/AppIcon.appiconset` + `Contents.json`; wire `ASSETCATALOG_COMPILER_APPICON_NAME`; regenerate
- [x] 1.3 Verify the icon on the simulator home screen

## 2. Button horizontal padding

- [x] 2.1 Add `.padding(.horizontal, Spacing.lg)` to `PrimaryButtonStyle` and `SecondaryButtonStyle` (before the width frame) (spec: design-components)
- [x] 2.2 Re-record the affected snapshots (design-system buttons; config empty state; workout finished / save-failed); review that "Done", "Create your first workout", and "Retry" now read as comfortable pills
- [x] 2.3 `./scripts/test.sh` + `./scripts/snapshot.sh` green; `./scripts/lint.sh` strict clean; `openspec validate ui-polish` clean

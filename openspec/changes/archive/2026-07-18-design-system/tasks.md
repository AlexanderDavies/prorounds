## 1. Snapshot tooling & module setup

- [x] 1.1 Add swift-snapshot-testing as a test-only dependency wired into a new `ProRoundsDesignSystemTests` target (design-system target only); commit `Package.resolved`
- [x] 1.2 Add `scripts/snapshot.sh` running `xcodebuild test` for the design-system snapshot tests on a pinned iOS simulator (iPhone 17 Pro); document it in the README
- [x] 1.3 Update `scripts/coverage.sh` to exclude `Sources/ProRoundsDesignSystem/**` from the denominator (engine still included); add the snapshot step to CI (spec: build-tooling)
- [x] 1.4 Confirm `./scripts/test.sh` (macOS) still builds/passes with the snapshot dep present and UIKit-guarded tests skipped (spec: build-tooling)

## 2. Design tokens (DESIGN.md §2–§4)

- [x] 2.1 Add `ThemeColor` (light/dark `Color` pair, `ShapeStyle` resolving on `colorScheme`) + a `Color(hex:)` helper
- [x] 2.2 Expose the semantic color namespace (`ProRoundsColor.accent/.canvas/.surface*/.border/.text*/.phase*/.track`) for the §3 roles; logic test that the accent is `#E50914` and canvas/text invert light↔dark (spec: design-tokens)
- [x] 2.3 Add spacing (8-pt grid), radius, and elevation token APIs; test the documented step values (spec: design-tokens)
- [x] 2.4 Add the typography roles (timer/display/title/headline/body/caption/overline), timer numeral monospaced; test the scale exists and the timer role is monospaced (spec: design-tokens)

## 3. Core components (DESIGN.md §6)

- [x] 3.1 Button styles: primary / secondary / tertiary / destructive / icon, with pressed + disabled states, token-driven (spec: design-components)
- [x] 3.2 `PhaseBadge`: overline pill with phase label + color (PREPARE / ROUND n / N / REST / DONE) (spec: design-components)
- [x] 3.3 `TimerRing`: phase-colored arc over dim track, injected `progress` fraction + pre-formatted numeral, center stack (badge · numeral · total-remaining) (spec: design-components)
- [x] 3.4 `TransportControls`: play/pause primary + reset, injected callbacks + running/paused + reset-enabled state (spec: design-components)
- [x] 3.5 `ConfigCard`: type icon + name + metadata line + trailing total/chevron, from injected strings (spec: design-components)
- [x] 3.6 Add SwiftUI `#Preview`s for each component (light/dark) for design iteration

## 4. Snapshot tests (light + dark + Dynamic Type)

- [x] 4.1 Snapshot-test each component in light and dark on the pinned simulator, recording committed references (spec: design-components)
- [x] 4.2 Add a larger Dynamic Type snapshot for the text-bearing components (PhaseBadge, ConfigCard, buttons) to catch layout breakage (spec: design-components)
- [x] 4.3 Verify a deliberate visual change fails a snapshot, then revert — proves the guard works (spec: design-components)

## 5. Verification

- [x] 5.1 `./scripts/snapshot.sh` green on the simulator; review the generated reference PNGs in light + dark for on-brand fidelity (spec: build-tooling)
- [x] 5.2 `./scripts/test.sh` + `./scripts/coverage.sh` green (engine still included, DesignSystem excluded); `./scripts/lint.sh` strict clean
- [x] 5.3 Module graph still compiles (DesignSystem imports no Data/Feature); `openspec validate design-system` clean; README updated

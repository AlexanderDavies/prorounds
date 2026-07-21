## Why

Every screen ahead (config list, config editor, the workout hero, performance, settings) composes the same visual language — the black/red cinematic theme in `docs/DESIGN.md`. Building `ProRoundsDesignSystem` now, with semantic tokens and the core components snapshot-tested in light and dark, means features assemble proven, on-brand pieces instead of re-styling ad hoc, and visual regressions fail the build.

## What Changes

- Implement the **semantic token system** from `DESIGN.md` §2–§4 in `ProRoundsDesignSystem`: colors (code-based light/dark tokens), spacing (8-pt grid), radius, elevation, and a typography scale — exposed as a semantic Swift API (`ProRoundsColor.accent`, `Spacing.md`, `Radius.lg`, `ProRoundsFont.timer`, …). `DESIGN.md` remains the source of truth; no feature hard-codes a hex or size.
- Build the **core components** (`DESIGN.md` §6): the button styles (primary / secondary / tertiary / destructive / icon), `TimerRing` (phase-colored progress ring + center stack), `PhaseBadge`, `TransportControls` (play/pause + reset cluster), and `ConfigCard`. Each takes injected, pre-formatted inputs and holds no product logic.
- Add **snapshot tests** (swift-snapshot-testing, a **test-only** dependency) for every component in **light + dark + a larger Dynamic Type size**, run on the iOS simulator via a new `scripts/snapshot.sh`. Reference images are the visual regression guard.
- Keep `ProRoundsDesignSystem` **cross-platform-buildable** (SwiftUI + asset-catalog colors, no UIKit-only APIs) so the existing macOS `swift test` loop — especially the engine's — stays fast; snapshot tests are `#if canImport(UIKit)`-guarded.
- Update the **coverage gate** to exclude the declarative DesignSystem module (guide §14.4) and add the snapshot step to CI.

Non-goals (deferred to the change that needs them): the **chart card** (§6.8 → change #8, needs Swift Charts + shaped data), the **stepper / value field** (§6.6 → change #5 config editor), the **sound-option row** and **theme toggle wiring** (§6.9 / §7.5 → change #9 settings), and restyling the app shell (the tabs stay placeholder until their feature changes). Components are verified via snapshots, not by wiring them into the app yet.

## Capabilities

### New Capabilities
- `design-tokens`: The semantic token layer — light/dark colors, spacing, radius, elevation, and typography — implementing `DESIGN.md` §2–§4, resolving for both appearances.
- `design-components`: The reusable, logic-free components (buttons, `TimerRing`, `PhaseBadge`, `TransportControls`, `ConfigCard`), each snapshot-tested in light + dark + Dynamic Type.

### Modified Capabilities
- `build-tooling`: Add the visual-regression workflow — swift-snapshot-testing as a test-only dependency, `scripts/snapshot.sh` running snapshots on the iOS simulator, a CI step for it, and a coverage-gate exclusion for the declarative design-system module.

## Impact

- **Fleshes out** the `ProRoundsDesignSystem` placeholder module (tokens + components + an asset catalog resource) and adds its snapshot test target.
- **Adds a test-only dependency** (swift-snapshot-testing) resolved at build time; it never ships in the app and does not touch the local-first runtime (no network at runtime, invariant preserved). `Package.resolved` is committed for reproducibility.
- **New/changed tooling:** `scripts/snapshot.sh` (iOS-simulator snapshot run), a CI job step, and a `coverage.sh` exclusion. `swift test` (macOS logic loop) is unchanged and still green.
- **No app or `project.yml` change**, no persistence, no network — the design system is standalone and verified by its reference images.

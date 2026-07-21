## Why

ProRounds has a product spec, a design system, and an architecture guide, but no code. Every later feature (the timer engine, config, workout runtime, charts, settings) depends on a compiling, test-green, launchable foundation with the layering already enforced by the package graph. This change establishes that foundation so subsequent changes plug into stable seams instead of re-litigating structure.

## What Changes

- Add **XcodeGen** `project.yml` that generates `ProRounds.xcodeproj` (git-ignored), plus a `ProRoundsApp` `@main` entry point and composition root.
- Stand up the **SwiftPM layered package skeleton** per `ARCHITECTURE_GUIDE.md` §2.1, with each package's `Package.swift` declaring only allowed dependencies so the dependency direction is compile-enforced from day one. Packages created empty-but-compiling except the two below.
- Implement `ProRoundsFoundationTiming`: a `TimeSource` protocol, a real `ContinuousClock`-backed implementation, and a `FakeTimeSource` for tests (deterministic, manually advanced, monotonic).
- Implement `ProRoundsFoundationUtilities`: `Duration`/time math plus the **single-source** total-workout-duration calculator and the auto-generated config-name formatter (e.g. "Heavy Bag · 12×3min / 1min rest").
- Add an **empty 3-tab app shell** — a root `TabView` with Timer / Performance / Settings tabs (placeholder content), so the app launches and navigates.
- Add **SwiftLint** config, a **CI workflow** (build + test + coverage gate, engine never excluded), and a **README** documenting how to generate the project, build, run, and test.

Non-goals (explicitly deferred): the RoundTimerEngine, any persistence/SwiftData, the design-system tokens/components, and all real screen content. Those are later changes in the roadmap.

## Capabilities

### New Capabilities
- `build-tooling`: The project generation, layered SwiftPM package graph with compile-enforced dependency direction, lint, CI, and the coverage gate that every later change relies on.
- `app-shell`: The root three-tab navigation shell (Timer / Performance / Settings) the app launches into.
- `time-source`: The injectable `TimeSource` clock seam — a real monotonic implementation plus a deterministic fake — that makes timing testable.
- `duration-formatting`: The single-source total-workout-duration calculation and auto-generated configuration-name formatting used across the app.

### Modified Capabilities
<!-- None — this is the first change; no existing specs. -->

## Impact

- **New files/dirs:** `project.yml`, `ProRounds/` (app target + composition root), `Packages/*` (package skeleton), `.swiftlint.yml`, `.github/workflows/*` (or equivalent CI), `README.md` updates, `.gitignore` for the generated `.xcodeproj`.
- **Tooling dependency:** developers/CI need XcodeGen and SwiftLint installed (documented in README).
- **No runtime dependencies added** beyond Apple frameworks; local-first invariant preserved (no network).
- **Foundation for all later changes** — establishes the seams (`TimeSource`) and derived-value homes (duration/auto-name) later features import.

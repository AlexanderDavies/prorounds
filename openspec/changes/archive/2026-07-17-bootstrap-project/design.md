## Context

ProRounds is a local-first SwiftUI/iOS 17+ boxing round-timer whose architecture is already specified in `docs/ARCHITECTURE_GUIDE.md` (layered SwiftPM packages, mandatory TDD, protocol seams for anything with side effects) and whose product/design are in `prorounds_app_prompt.md` and `docs/DESIGN.md`. No code exists yet. This change is purely structural: it must produce the scaffold that all nine roadmap changes build on, while committing to as little product behavior as possible. The two seams built here — `TimeSource` and the duration/auto-name utilities — are chosen because the very next change (the RoundTimerEngine) is written test-first and cannot compile its tests without them.

## Goals / Non-Goals

**Goals:**
- A clean checkout can generate the project, build, launch to a 3-tab shell in the simulator, and run the test suite to green.
- The package graph compiles the layering rules of §2.1 so later changes physically cannot violate dependency direction.
- `TimeSource` (real + fake) and the single-source duration/auto-name calculators exist, are unit-tested, and are ready to inject.
- CI enforces build + test + coverage (engine never excluded) and SwiftLint.

**Non-Goals:**
- No `RoundTimerEngine`, no phase state machine (change #2).
- No SwiftData / persistence / repositories (change #4+).
- No design-system tokens or components (change #3) — the shell uses plain SwiftUI placeholders.
- No real screen content, audio, charts, or settings behavior.

## Decisions

- **XcodeGen over a committed `.xcodeproj`.** Keeps the project definition reviewable in `project.yml` and avoids merge conflicts in generated pbxproj; the `.xcodeproj` is git-ignored and regenerated. Alternative — commit the xcodeproj — rejected for review noise and conflict risk. Alternative — pure SwiftPM app — rejected because the app target needs Xcode project settings (entitlements, assets, simulator run) that XcodeGen expresses cleanly.
- **Full module skeleton now via a single root `Package.swift`, empty-but-compiling.** §2.1 offers a "pragmatic path" (start with folders, split later). We declare all 12 §2.1 modules as **library targets in one root `Package.swift`**, filling only `FoundationTiming` and `FoundationUtilities` this change; the rest are placeholder library targets. Target-level dependencies enforce the layering identically to per-package manifests — a target importing a module not in its `dependencies` fails to compile — while keeping every `ProRounds<Layer><Feature>` module name. Rationale over 12 separate packages: (a) one `swift test` runs the whole suite, which is what the `build-tooling` spec and §0.5 "runnable + testable locally" require (12 path-linked packages have no single test command); (b) far less manifest ceremony for a small app; (c) the enforced direction — the whole point of the scaffold — is preserved. Timing and Utilities are non-empty because change #2 depends on them. Later changes flesh out a module's sources rather than adding a new package.
- **`TimeSource` protocol shape.** Expose a monotonic `now` instant plus an async `sleep(until:)`/scheduling primitive over `ContinuousClock`, so the engine can await deadlines rather than accumulate ticks (§7.2). `FakeTimeSource` stores a mutable instant and a queue of pending continuations released when the test advances past their deadline — deterministic, no real time. Alternative — inject `ContinuousClock` directly — rejected because a concrete clock is not substitutable in tests without a protocol.
- **Derived values have one home (§6.5).** Total-duration and auto-name live in `FoundationUtilities` as free functions / a small value type, reused by config editor, config card, and session summary. Prevents the classic drift where the list and the editor compute totals differently.
- **Placeholder shell, not throwaway.** The `TabView` and its three tabs are the real root that later changes replace tab *contents* of; the shell structure itself persists. Tab symbols/labels already match DESIGN.md §5 so we don't re-touch them later.

## Risks / Trade-offs

- **Empty packages add ceremony for a small app** → Mitigation: keep each empty `Package.swift` minimal; the §2.1 pragmatic-path note explicitly blesses this as the enforcement mechanism. If it proves heavy, packages can be collapsed later without changing import direction.
- **XcodeGen/SwiftLint are extra local tooling a contributor must install** → Mitigation: document exact install steps and versions in README; CI pins them.
- **Background-audio behavior is still an open product question** (flagged in the app prompt) → Not a risk for this change (no audio here); deferred to change #6 and recorded as an open question there.
- **Coverage gate on a near-empty codebase can be noisy** → Mitigation: the utilities and TimeSource fake are unit-tested this change so the gate has real code to measure; view/app-entry exclusions are configured from the start.

## Open Questions

- Exact XcodeGen and SwiftLint versions to pin (resolve at implementation from what's installed locally).
- Whether CI runs on GitHub Actions vs another runner — assume GitHub Actions unless the user says otherwise; the workflow is simple to port.

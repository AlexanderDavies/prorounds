## Context

`docs/DESIGN.md` is the visual source of truth (tokens, component specs, per-screen layouts). This change implements the shared slice of it — tokens + the core components — in `ProRoundsDesignSystem`, which is Foundation-level (importable by Feature/App) and holds no product logic. It is the first SwiftUI/UI module in the codebase, so it also settles how UI is visually tested. Per the user's decision, snapshot tests use **swift-snapshot-testing** as a test-only dependency.

## Goals / Non-Goals

**Goals:**
- Semantic tokens (color light/dark, spacing, radius, elevation, typography) implementing `DESIGN.md` §2–§4.
- The core components: buttons, `TimerRing`, `PhaseBadge`, `TransportControls`, `ConfigCard` — logic-free, token-driven.
- Snapshot tests (light + dark + Dynamic Type) as the visual-regression guard, plus the tooling to run them.

**Non-Goals:**
- Chart card (§6.8 → #8), stepper/value field (§6.6 → #5), sound-option row + theme-toggle wiring (§6.9/§7.5 → #9).
- Wiring components into the app shell (tabs stay placeholder); no `project.yml` change.
- Any product logic, persistence, or data fetch in the design system.

## Decisions

- **D1 — Cross-platform module, iOS-only snapshots.** `ProRoundsDesignSystem` is built with cross-platform SwiftUI and asset-catalog colors — **no UIKit-only APIs** — so it compiles on the macOS host and the existing `swift test` logic loop (critically, the engine's) stays fast and intact. Snapshot tests, which render to images via UIKit, live in the design-system test target guarded by `#if canImport(UIKit)` and run only on the iOS simulator. Alternative — an iOS-only design system — rejected because `ProRoundsFeatureTimer` depends on it, which would force the engine's tests onto the simulator and lose the microsecond macOS loop.
- **D2 — Code-based light/dark tokens (no asset catalog).** Colors are a `ThemeColor` value holding a light and a dark `Color`, conforming to `ShapeStyle` and resolving via `resolve(in:)` on `environment.colorScheme`; the hex is written once with a `Color(hex:)` helper (the implementation of `DESIGN.md` §3). A semantic namespace (`ProRoundsColor.accent/.canvas/.textPrimary/.phaseRound…`, `Spacing`, `Radius`, `ProRoundsFont`) exposes them so features never touch raw values. Rationale over an `.xcassets`: an asset catalog must be compiled by `actool` (full Xcode), which would jeopardize the plain macOS `swift test`/engine loop in this split-toolchain environment; code-based tokens need no Xcode tooling, build anywhere, and render identically in the iOS snapshots. Typography is exposed as `FontToken` values (size/weight/monospaced) so the scale is unit-testable without introspecting an opaque `Font`.
- **D3 — swift-snapshot-testing, test-only, references committed.** Added only to the design-system test target; it resolves at build time and never ships (local-first runtime unaffected — no runtime network). `Package.resolved` is committed for reproducibility. `scripts/snapshot.sh` runs `xcodebuild test` on a **pinned simulator device** (iPhone 17 Pro) so reference images are stable; first run records, subsequent runs compare. Use `perceptualPrecision` slightly below 1.0 to tolerate benign GPU/AA differences.
- **D4 — Component API shape.** Each component takes injected, already-formatted values (strings, a progress `Double`, phase color, callbacks) — never a `Configuration`, a clock, or the engine. `TimerRing` takes `progress: Double` + a pre-formatted numeral (count direction resolved by the caller per §7.6). This keeps components pure and snapshot-deterministic and avoids a Data/Feature import.
- **D5 — Coverage gate excludes the design-system views.** Per guide §14.4, declarative view code is out of the coverage denominator; `coverage.sh` drops `Sources/ProRoundsDesignSystem/**`. The engine remains included. Visual correctness is enforced by snapshots instead of line coverage.
- **D6 — Verification via reference images.** Because snapshots write PNG references, the change is visually verified by generating and viewing those images in light and dark — no need to wire components into the app this change.

## Risks / Trade-offs

- **Snapshot brittleness across Xcode/OS/device** → Mitigation: pin the simulator device+OS in `scripts/snapshot.sh`; use `perceptualPrecision`; document that references are regenerated intentionally when the design changes (never blindly re-recorded to make a test pass).
- **Asset-catalog-in-SwiftPM resource wiring can be finicky** (`Bundle.module`, processing rules) → Mitigation: declare the catalog under `resources: [.process(...)]`; a token test asserts the accent resolves, catching a mis-wired bundle early.
- **swift-snapshot-testing on the macOS build** (it links into the test target even though its tests are iOS-guarded) → Mitigation: the library builds on macOS; the guarded tests compile to nothing there, so `swift test` stays green with zero snapshot tests run.
- **Committing binary reference PNGs** grows the repo → Acceptable and standard; kept small (a handful of components × 3 variants), and they are the regression guard's ground truth.

## Open Questions

- Final **SF Symbol per workout type** (DESIGN §5 flags this as availability-dependent) — pick sensible glyphs with a fallback for `ConfigCard`; revisit if a symbol is unavailable on the deployment target.
- Exact **Dynamic Type size** to snapshot at (e.g. `.accessibility1` vs `.xxxLarge`) — choose one representative large size at implementation; the point is to catch layout breakage, not to cover every size.

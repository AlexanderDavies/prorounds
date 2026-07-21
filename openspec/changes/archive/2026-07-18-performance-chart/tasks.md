## 1. Palette token & module setup

- [x] 1.1 Add `ProRoundsColor.chartColor(for: WorkoutType)` (DESIGN §7.5 categorical palette) to the design system + a token test; validate the palette with the **dataviz skill**
- [x] 1.2 Add the `ProRoundsFeaturePerformanceTests` test target to `Package.swift` (with SnapshotTesting + `__Snapshots__` excluded)

## 2. Aggregation (pure)

- [x] 2.1 Write failing tests for `PerformanceMetrics.make(sessions:range:referenceDate:calendar:)`: per-type + total active-minutes series; active minutes exclude rest/prep; Week/Month/All range filtering; summary figures (active minutes, sessions, rounds) (spec: performance-metrics)
- [x] 2.2 Implement `PerformanceMetrics` + the series/summary value types (keyed by `WorkoutType`, `nil` = total; buckets per range) — green

## 3. View model

- [x] 3.1 Write failing `PerformanceViewModel` tests (over an in-memory `SwiftDataSessionRepository`): load builds series + tiles; changing range recomputes without refetch; toggling a legend series hides it; empty when no sessions (spec: performance-chart)
- [x] 3.2 Implement `@MainActor @Observable PerformanceViewModel` (load, `range`, `hiddenSeries`, derived display) — green

## 4. Chart screen

- [x] 4.1 Build `PerformanceView` (dumb) with Swift Charts — per-type lines + heavier Total, X = date / Y = minutes, animations off; range segmented control; tappable legend; summary tiles; empty state; compose design tokens (spec: performance-chart). Follow the **dataviz skill** for axes/legend/contrast
- [x] 4.2 Add chart snapshot tests (populated + empty) light + dark, from injected fixed series

## 5. Composition & verification

- [x] 5.1 Composition root: `ViewModelFactory.performance()`; wire the Performance tab to `PerformanceView`; `project.yml` gains `ProRoundsFeaturePerformance`; regenerate
- [x] 5.2 `./scripts/test.sh` + `./scripts/coverage.sh` green (engine included, views excluded); `./scripts/lint.sh` strict clean; `./scripts/snapshot.sh` green
- [x] 5.3 Chart appearance verified via snapshots (populated + empty, light + dark — the populated one caught a real Swift Charts bug: missing `series:` made all lines one tangled series; fixed). Performance-tab wiring verified end-to-end by an XCUITest (tap Performance tab → empty state appears, since the seed has a config but no sessions). Composition confirmed by the app build
- [x] 5.4 Module graph compiles (FeaturePerformance imports no sibling Feature; DesignSystem imports no Data/Feature); `openspec validate performance-chart` clean; README updated

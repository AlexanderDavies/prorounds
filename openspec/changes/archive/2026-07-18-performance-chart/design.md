## Context

Change #7 persists a `Session` per completed workout and exposes `SessionRepository.byWorkoutType()`. This change reads those sessions and renders training volume over time on the Performance tab with Swift Charts, per DESIGN §7.4/§7.5 and guide §13.3. The chart takes pre-shaped, injected data so it snapshots deterministically. The **dataviz skill** governs the palette, axes, legend, and light/dark contrast at build time.

## Goals / Non-Goals

**Goals:**
- Pure aggregation: sessions → active-minutes-over-time series (per type + total) + summary figures, filtered by range.
- A Swift Charts multi-line screen: range control, tappable legend, summary tiles, empty state.
- The Performance tab wired to it; aggregation unit-tested, the chart snapshot-tested.

**Non-Goals:**
- A raw session history list; biometric trends (Phase 2); settings (#9).

## Decisions

- **D1 — Everything in `ProRoundsFeaturePerformance`.** The view model, the pure aggregation (`PerformanceMetrics`), and the `PerformanceView` (Swift Charts) live here. DESIGN §6.8/§13.3 discuss the chart under the design system, but keeping it in the feature avoids the design system importing data/domain shapes; rule of three (one consumer) says don't promote yet. The categorical **palette** *is* a design token, so it goes in the design system: `ProRoundsColor.chartColor(for: WorkoutType)` (DesignSystem may reference `WorkoutType`, which lives in FoundationUtilities), with Total = `textPrimary`.
- **D2 — Pure, injected aggregation.** `PerformanceMetrics.make(sessions:range:referenceDate:calendar:)` returns series keyed by `WorkoutType` (+ a total) of `(bucketDate, activeMinutes)` points plus the summary figures. It takes `referenceDate`/`calendar` so range filtering ("last week") and bucketing are deterministic in tests. Active minutes come from `Session.activeDuration` in minutes (`Double`). Bucket granularity: **Week → per day, Month → per day, All → per week**.
- **D3 — Chart from injected series.** `PerformanceView` renders `Chart { ForEach series { LineMark(x: .date, y: .minutes) } }` — per-type lines in their palette color, the Total line heavier in `textPrimary`. No fetch in the view. Animations are disabled for deterministic snapshots.
- **D4 — Range + legend are view-model state.** `PerformanceViewModel` loads all sessions once, holds `range` and `hiddenSeries: Set<SeriesID>`, and recomputes the display (via `PerformanceMetrics`) when either changes — no refetch. Tapping a legend entry toggles its series in `hiddenSeries`; the chart filters hidden series.
- **D5 — Empty state** when there are no sessions at all (not merely an empty range) — a clean invite rather than a blank chart; an empty *range* still shows the chart frame with the tiles at zero.
- **D6 — Composition.** `ViewModelFactory.performance()` builds `PerformanceViewModel(sessions: environment.sessionRepository)`; the Performance tab hosts `PerformanceView`. `project.yml` adds the `ProRoundsFeaturePerformance` product.

## Risks / Trade-offs

- **Swift Charts snapshot determinism** → fixed dates + data + disabled animations; snapshots use injected series, never `Date()`/live data.
- **Date bucketing / time zones** → inject `calendar`/`referenceDate` into aggregation; tests pin them. The view model uses `Date.now` + `.current` in production.
- **Legend-toggle + Swift Charts redraw** → keep it simple: hidden series are filtered out of the `ForEach`; assert the toggle in a view-model test, not a UI test.
- **Sparse/single-session data** → a single point still renders (a dot/short line); tested.

## Open Questions

- Bucket granularity per range (D2) is a sensible default; adjustable if the product wants weekly buckets for Month, etc.
- Whether the Total line should be toggleable like the others (D4 allows it) — kept toggleable for now.

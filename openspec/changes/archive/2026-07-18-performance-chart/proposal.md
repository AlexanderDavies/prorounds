## Why

Sessions are saved but invisible. The app prompt's Performance page turns them into a story: **training volume over time**, a line per workout type plus a total. This is where the loop pays off — the user sees their trend — and it's the consumer of the `SessionRepository.byWorkoutType()` grouping built in change #7.

## What Changes

- Build **`ProRoundsFeaturePerformance`** — the Performance tab (guide §3, DESIGN §7.4):
  - A `@MainActor @Observable PerformanceViewModel` over the `SessionRepository` that reads sessions and maps them to **active-minutes-over-time series** — one per workout type plus a heavier **Total** aggregate — bucketed by the selected time range (Week / Month / All), with **summary tiles** (this period's active minutes, session count, rounds completed).
  - A dumb `PerformanceView` rendering the series with **Swift Charts** (a `radius.xl` chart card), a **range segmented control**, a **tappable legend** to isolate/toggle a series, the summary tiles, and an **empty state** ("Complete a workout to see your trends").
- The Y-metric is **total active minutes** (sum of round time; rest and prep excluded — the settled DESIGN §7.4 decision), which each `Session` already exposes as `activeDuration`.
- **Wire the Performance tab** to the chart (replacing its placeholder) and inject a `PerformanceViewModel` via the factory; add `ProRoundsFeaturePerformance` to the app target in `project.yml`.
- Apply the **dataviz skill** at build time for the categorical palette (per DESIGN §7.5), axes, legend, and light/dark contrast.

Non-goals (deferred): a raw session **history list**, biometric/WHOOP trend overlays (Phase 2), and **settings** (count-direction/theme/sound) — change #9. The chart takes pre-shaped, injected data and never live-fetches inside the view (guide §13.3).

## Capabilities

### New Capabilities
- `performance-metrics`: The aggregation — sessions → active-minutes-over-time series per workout type + a total aggregate, filtered by range, plus the summary-tile figures. Pure and unit-tested.
- `performance-chart`: The Performance screen — the Swift Charts multi-line chart, range control, tappable legend, summary tiles, and empty state, rendered from injected series.

### Modified Capabilities
- `app-shell`: The Performance tab shows the performance chart (was a placeholder).

## Impact

- **Fleshes out** the `ProRoundsFeaturePerformance` placeholder module (view model + aggregation + chart view) and extends the composition root (a `PerformanceViewModel` from the shared `SessionRepository`).
- **`project.yml`**: the app target gains `ProRoundsFeaturePerformance`; regenerate.
- Aggregation logic unit-tested against an in-memory `SessionRepository` (fast macOS loop); the chart snapshot-tested with fixed data (populated + empty, light + dark) — deterministic because the chart takes injected, pre-shaped series (guide §13.3).
- **First use of Swift Charts** (an Apple framework — no third-party). Local-first preserved.

## Context

`RootView` holds `@State workoutPath: [Configuration]` driving the Timer tab's `NavigationStack`.
Because SwiftUI preserves each tab's view state, the path survives tab switches — so returning to
Timer re-shows the pushed `WorkoutView`. That view's `onDisappear` already reset the engine, leaving a
running screen whose transport can't drive anything (the reported "Play does nothing").

## Goals / Non-Goals

- **Goal:** re-selecting the Timer tab returns to the configuration list (home).
- **Non-Goals:** no "pop-to-root on re-tap of the already-selected tab" gesture (out of scope); no
  change to the engine, the workout view model, or the idle/Play flow itself.

## Decisions

### Clear the Timer path on any tab change

Add `@State selectedTab: Tab` with a `TabView(selection:)` and `.tag(...)` per tab, then
`.onChange(of: selectedTab) { _, _ in workoutPath.removeAll() }`. Only the Timer tab has a path, so
clearing it on every change means: leaving Timer empties it, and returning shows the list. This is
simpler and more robust than trying to detect the specific Settings→Timer transition, and it makes
"the Timer button takes me home" always true.

A fresh `WorkoutView` (hence a fresh view model + engine) is built by the `navigationDestination` the
next time a card is tapped, so the previous stale instance is gone entirely.

## Risks / Trade-offs

- **Abandoning an in-progress workout on tab switch:** already the effective behaviour (the engine is
  reset on the workout screen's disappearance and nothing is saved unless a workout naturally
  finishes), so no session is lost that wasn't already being discarded.

## Migration Plan

App-target UI change only; no data or module migration. Verified by XCUITest (updated for the
idle-first screen, plus a new leave-and-return-to-Timer assertion).

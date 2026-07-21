## Why

The Timer tab's `NavigationStack` keeps its path across tab switches, so opening a workout, tapping
Settings, then tapping Timer again returns to the **individual workout screen** instead of home — and
that retained screen is half torn down (its engine was reset on disappear), so the Play button appears
to do nothing. The user expects the Timer tab button to take them back to the home (configuration)
screen. (From hands-on use.)

## What Changes

- **Switching tabs returns the Timer tab to its root (the configuration list).** The root `TabView`
  gains a selection binding; on any tab change the Timer tab's navigation path is cleared, so
  re-selecting Timer opens home — never a stale workout screen. Any in-progress workout is abandoned
  (its engine is already reset on the screen's disappearance).

## Capabilities

### Modified Capabilities
- `app-shell`: switching tabs returns the Timer tab to the Configurations list (a new requirement).

## Impact

- `RootView` (app target): add a `Tab` selection binding + `.tag(...)` on each tab; clear
  `workoutPath` on `onChange(of: selectedTab)`.
- Update the XCUITest for the idle-first workout screen (tap card → Play, not auto-running) and add a
  test that leaving to Settings and returning to Timer shows the list. No package/module changes; no
  spec changes beyond `app-shell`.

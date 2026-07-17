# ProRounds — Build Prompt

## Overview

Build **ProRounds**, a boxing round-timer app for iOS. It is a simple, single-user,
**local-only** app: no login, no user accounts, no backend server. All data (configurations
and session history) is persisted on-device.

The core loop: the user configures a set of rounds, starts the workout, and the app runs a
timer through preparation → rounds → rests, with audio cues. Every completed workout is saved
as a session, and sessions can be visualised over time on a dedicated performance page.

## Tech constraints

- **SwiftUI**, iOS 17+.
- **SwiftData** for on-device persistence (configurations + session history).
- Bundled audio assets for the warning sounds. No network calls in the MVP.
- Support **light and dark mode** with a user-facing toggle (persisted).

## MVP — Feature specification

### 1. Round configuration

A configuration consists of:

- **Workout type** — enum, presented in this order: `Shadow Boxing`, `Skipping`, `Heavy Bag`,
  `Speed Ball`, `Sparring`.
- **Number of rounds**
- **Round time** (duration of each round)
- **Rest time** (between rounds)
- **Preparation time** (before the first round)
- **Round-end warning lead time** — the warning sound plays this many seconds before each
  round ends (e.g. 10s). User-configurable; can be turned off (0 = none).

The user can:

- **Save** a configuration with a custom name, or **default to a meaningful auto-generated
  name** derived from the workout type, number of rounds, round duration and rest period
  (e.g. "Heavy Bag · 12×3min / 1min rest").
- **Select** from saved configurations, or tap **+** to create a new one.
- Presumably edit and delete saved configurations (standard list management).

### 2. Timer / workout runtime

When the user starts a workout, the timer runs strictly according to the configuration:
preparation time → (round → rest) × number of rounds. No rest after the final round.

Controls and display:

- **Pause**, **Resume** (from paused), and **Reset**.
- Show **which round** the user is in (e.g. "Round 3 of 12") and the **current phase**
  (Prep / Round / Rest).
- Show the **countdown (or count-up — see Settings) of the current phase**.
- Show the **total time** across the whole configured workout (sum of every round + every
  rest + prep).
- Play audio cues: a bell/signal at **round start** and **round end**, and the configured
  **warning sound** at the round-end warning lead time.
- Keep the screen awake and the timer accurate while running (including when backgrounded, if
  feasible — clarify if this needs full background-audio handling).

### 3. Session history

- Every completed workout is **saved as a session** capturing the key details: date/time,
  workout type, configuration used (name + parameters), number of rounds completed, and total
  active/elapsed time.
- Sessions persist across launches.

### 4. Performance page (chart)

- A **separate page**, reached via a **chart-outline icon in the bottom tab bar**. Tapping it
  navigates to the performance view.
- Visualise **training volume over time** as a sleek **line chart**:
  - A line **per workout type** (Shadow Boxing / Skipping / Heavy Bag / Speed Ball / Sparring),
  - plus a **total aggregate** line across all types.
- Use Swift Charts. Keep it clean and on-brand (see Design).

### 5. Settings

- **Warning sound** selection:
  - Clap of two wooden blocks
  - Electronic horn
  - Buzzer
- **Countdown vs count-up** toggle for the timer display.
- **Light / dark mode** toggle.

## Design

- **Black and red** theme; sleek and minimal.
- Follow **Netflix's design principles / look and feel** — dark-first, bold typography,
  edge-to-edge content, high contrast, confident use of red accents.
- Smooth transitions and a polished, premium feel.
- Fully functional in both **light and dark mode**.

## Phase 2 (NOT in this build — architect so it can be added later)

Do not implement these now, but keep the data and app structure flexible enough to add them:

- **WHOOP integration** to track biometric trends during rounds (OAuth + WHOOP API — will
  require developer credentials).
- **Metrics as trends over time** alongside the existing training-volume chart.
- **Live heart-rate during a workout**: a visual "beep" pulse synced to heart rate while
  rounds run, plus the live BPM number updating over time.

## Assumptions to confirm

Flag anything below that's wrong before building:

- SwiftData + SwiftUI, iOS 17+, no third-party dependencies in the MVP.
- Standard edit/delete for saved configurations.
- Timer should keep running accurately when the app is backgrounded (may need background-audio
  entitlement) — confirm required behaviour.

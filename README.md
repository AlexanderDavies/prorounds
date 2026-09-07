# ProRounds

A local-first boxing round-timer for iOS (Swift 6 / SwiftUI, iOS 17+). No login, no backend —
configurations, sessions, and settings all persist on-device. The heart of the app is a
deterministic, clock-injected round-timer engine; audio cues, charts, and a black/red
cinematic theme sit around it.

- **Product spec:** [`prorounds_app_prompt.md`](prorounds_app_prompt.md)
- **Architecture guide:** [`docs/ARCHITECTURE_GUIDE.md`](docs/ARCHITECTURE_GUIDE.md) — read before feature work
- **Design system:** [`docs/DESIGN.md`](docs/DESIGN.md) · mockups in [`docs/mockups/`](docs/mockups)
- **Coach scripts:** [`docs/coaching/`](docs/coaching) — assisted-coaching content, `scripts/coach-script.py`, and the voice-clip pipeline
- **Build plan:** managed as sequential OpenSpec changes under [`openspec/changes/`](openspec/changes)

## Requirements

| Tool | Why | Install |
|------|-----|---------|
| **Xcode 16+** (full, not just Command Line Tools) | Build the iOS app target and run the simulator | App Store / [developer.apple.com](https://developer.apple.com/xcode/) |
| **XcodeGen** | Generates `ProRounds.xcodeproj` from `project.yml` | `brew install xcodegen` |
| **SwiftLint** | Lint gate | `brew install swiftlint` |

The Xcode project is **generated** and git-ignored — never edit or commit `ProRounds.xcodeproj`.
Change `project.yml` and regenerate.

> **Command Line Tools only?** The logic packages still build and test (`scripts/test.sh` supplies
> the Swift Testing framework paths automatically), but building the app target and running the
> simulator require full Xcode.

## Project layout

```
Package.swift          # the layered module graph (see below)
Sources/               # one folder per module
Tests/                 # Swift Testing suites (FoundationTiming, FoundationUtilities so far)
ProRounds/             # the iOS app target: @main entry + the 3-tab shell
project.yml            # XcodeGen definition of the app target + scheme
scripts/               # test.sh · lint.sh · coverage.sh · coach-script.py · gen-coach-clips.py
docs/                  # architecture guide, design system, mockups, coach scripts
openspec/              # spec-driven change proposals
```

### Module graph (compile-enforced)

All modules live in the root `Package.swift` as library targets named `ProRounds<Layer><Feature>`
(guide §2.1). The layering is **Foundation ← Data ← Feature**, with DesignSystem available to
Data/Feature, and no Feature depending on a sibling Feature.

**This is enforced by a test, not by the compiler.** SwiftPM lets a target import any other target in
the same package whether or not it declares the dependency — verified: `ProRoundsFeatureTimer` can
`import ProRoundsFeaturePerformance` and build, which the guide forbids outright. The only case the
toolchain catches by itself is a dependency *cycle*. So `ProRoundsArchitectureTests` parses
`Package.swift` and asserts the graph, and it is mutation-checked: a Feature→Feature edge and a
Foundation→Data inversion both fail it. Declare every module you import.

Real code so far: `ProRoundsFoundationTiming` (the injectable `TimeSource` clock seam +
`FakeTimeSource` + tick stream), `ProRoundsFoundationUtilities` (single-source total-duration /
auto-name / formatting + `WorkoutType`), `ProRoundsFoundationAudio` (the `AudioCuePlayer` seam +
cue types), `ProRoundsFoundationPersistence` (the generic SwiftData `ModelContainer` factory),
`ProRoundsDataConfig` (the `Configuration` domain type, `ConfigurationRepository` +
SwiftData store + `ConfigurationValidator`), `ProRoundsFeatureTimer` (the `RoundTimerEngine`),
`ProRoundsDesignSystem` (black/red tokens + core components), `ProRoundsFeatureConfig` (the
Configurations list + editor), and `ProRoundsFeatureTimer` (the `RoundTimerEngine` + the running
workout screen). `ProRoundsFoundationAudio` carries the concrete `AVAudioCuePlayer` with bundled
sounds and background-audio. `ProRoundsDataSessions` persists a `Session` for every completed
workout (via `SessionRepository`, `byWorkoutType()` for the chart), and `ProRoundsFeaturePerformance`
renders training-volume-over-time with Swift Charts, and `ProRoundsFeatureSettings` (+
`ProRoundsDataSettings`) owns the warning sound, timer display, and appearance preferences.
`ProRoundsFoundationCoaching` holds the assisted-coaching catalog and cue scheduler — pure, with no
audio and no UI. It ships the 115 voice clips and reproduces `scripts/coach-script.py` byte for byte,
which its tests assert against committed fixtures. It also owns the `EntitlementStore` seam, which
the composition root constructs. A `Configuration` carries an optional `CoachingLevel`, and the
naming convention plus the minimal-screen preference live in `SettingsStore`. Cue playback and the
running-screen ticker are not built yet. The app
target hosts the **composition root** (`AppEnvironment` + `ViewModelFactory`, one shared store for
configs + sessions, a shared `SettingsViewModel` driving `preferredColorScheme`); the Timer tab runs
workouts (saving a session on completion), Performance shows the chart, and Settings persists
preferences. **All three tabs are real — the MVP is feature-complete.** The only remaining placeholder
is `ProRoundsFoundationDiagnostics` (observability, out of MVP scope).

The chart's categorical palette (`ProRoundsColor.chartColor(for:)`) was validated with the dataviz
skill (all six checks, both light and dark surfaces).

The placeholder sound assets are generated by `scripts/gen-audio.sh` (committed WAVs — swap for real
audio later). A UI flow test (`ProRoundsUITests`) drives list → open (idle) → play → pause → resume →
reset, and checks that leaving to another tab and back returns the Timer tab to the list; run it with:

```bash
xcodebuild test -project ProRounds.xcodeproj -scheme ProRounds \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ProRoundsUITests CODE_SIGNING_ALLOWED=NO
```

## Common commands

```bash
# Generate the Xcode project (after any project.yml change)
xcodegen generate

# Run the logic test suite (Swift Testing, macOS host). Runs serially — see the note in test.sh:
# the schema-migration fixture registers a second model under the shipped entity's name, which is
# not safe to have live concurrently with the real one.
./scripts/test.sh

# Lint (strict — any violation fails)
./scripts/lint.sh

# Tests + coverage gate (default 90%; engine always included, DesignSystem views excluded)
./scripts/coverage.sh

# Design-system + running-screen snapshot tests (iOS simulator). Re-record with RECORD=1.
# RECORD passes TEST_RUNNER_SNAPSHOT_TESTING_RECORD to xcodebuild — a plain `export` does not
# reach the test process, which is why re-recording silently did nothing before.
# Works here: xcode-select reports Command Line Tools, but full Xcode is installed and the
# scripts fall back to it. Checking `xcode-select -p` alone gives the wrong answer.
./scripts/snapshot.sh

# The app target. `swift test` does NOT compile ProRounds/, so the composition root is only
# type-checked here — two undeclared module imports reached main before this was run.
xcodebuild -project ProRounds.xcodeproj -scheme ProRounds \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# Coach-script content checks (no Swift toolchain needed) — see docs/coaching/
./scripts/coach-script.py validate
./scripts/coach-script.py preview beginner_shadow --convention names

# Coach voice clips (needs ELEVENLABS_API_KEY; the voice itself is baked into the script)
./scripts/gen-coach-clips.py --dry-run   # what would be generated, and the character cost
./scripts/gen-coach-clips.py             # generate whatever is missing
./scripts/gen-coach-clips.py --measure   # no API calls: rewrite estMs from the clips on disk
```

The scripts prefer a full Xcode toolchain (they set `DEVELOPER_DIR` to `/Applications/Xcode.app`
when the selected developer dir is only Command Line Tools) — full Xcode ships both XCTest and
Swift Testing, so no special flags are needed. A CLT-only fallback exists for `test.sh`/`lint.sh`,
but the snapshot tests require full Xcode and an iOS simulator.

### Snapshot tests

Design-system components are covered by `swift-snapshot-testing` (a **test-only** dependency — it
never ships in the app). Reference images live in
`Tests/ProRoundsDesignSystemTests/__Snapshots__/` and are **device/OS-specific** (recorded on
`iPhone 17 Pro`). Regenerate them only on an intentional design change:

```bash
RECORD=1 ./scripts/snapshot.sh   # re-record, then review the PNGs and commit
```

## Build & run the app

```bash
xcodegen generate
open ProRounds.xcodeproj      # then ⌘R, or:
xcodebuild build -project ProRounds.xcodeproj -scheme ProRounds \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```

The app launches into the three-tab shell (Timer · Performance · Settings), Timer selected.
Tab contents are placeholders until their feature changes land.

## Testing & CI

TDD is mandatory (guide §14): red → green → refactor, Swift Testing against fakes, the
`RoundTimerEngine` written test-first against `FakeTimeSource`. CI
([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) runs lint → tests + coverage gate →
project generation → app build on every push and PR.

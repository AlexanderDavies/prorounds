## 1. Package skeleton & dependency graph

- [x] 1.1 Create a single root `Package.swift` declaring all 12 §2.1 modules as library targets (Foundation: Utilities, Diagnostics, Timing, Audio, Persistence; DesignSystem; Data: Config, Sessions, Settings; Feature: Timer, Config, Performance, Settings), each empty-but-compiling except Timing/Utilities; real test targets only for Timing and Utilities (empty modules get tests when their change fleshes them out)
- [x] 1.2 Declare only the layer-permitted target dependencies (Foundation ← Data ← Feature; DesignSystem available to Data/Feature; no sibling-feature deps); platforms `.iOS(.v17)` + `.macOS(.v14)` so host `swift test` runs
- [x] 1.3 Add a deliberate throwaway upward-import and confirm it fails to compile; remove it — proves the graph enforces direction (spec: build-tooling)

## 2. FoundationTiming — the TimeSource seam

- [x] 2.1 Write failing Swift Tests for `FakeTimeSource`: reads are stable without advancing; advancing moves `now` by exactly the requested duration; scheduled work due at/before the new instant fires (spec: time-source)
- [x] 2.2 Define the `TimeSource` protocol (monotonic `now` + async sleep/schedule-until) and implement `FakeTimeSource` to green
- [x] 2.3 Implement the real `ContinuousClock`-backed `TimeSource`; test that successive instants are monotonic non-decreasing

## 3. FoundationUtilities — duration & auto-name

- [x] 3.1 Write failing tests for total-workout-duration: `prep + round×N + rest×(N−1)`, no rest after final round, single-round case (spec: duration-formatting)
- [x] 3.2 Implement the single-source total-duration calculator to green
- [x] 3.3 Write failing tests for the auto-name formatter ("Heavy Bag · 12×3min / 1min rest") and the m:ss / h:mm:ss duration formatter; implement to green
- [x] 3.4 Confirm there is exactly one implementation of each derived value (no duplicate total/auto-name logic) (§6.5)

## 4. App target & 3-tab shell

- [x] 4.1 Add `project.yml` (XcodeGen) defining the `ProRounds` iOS 17+ app target wired to the local packages; add `ProRounds.xcodeproj` to `.gitignore`
- [x] 4.2 Create `ProRoundsApp` `@main` + a minimal composition root, and a root `TabView` with Timer / Performance / Settings tabs (SF Symbols `timer`, `chart.line.uptrend.xyaxis`, `gearshape`; Timer default) and placeholder content (spec: app-shell)
- [x] 4.3 Run in the simulator: app launches to the Timer tab, all three tabs switch, and it renders under both light and dark appearance — verified on iPhone 17 Pro sim (build succeeded, launched, Timer default-selected, light + dark both render legibly, all three tab items with correct SF Symbols)

## 5. Lint, CI & docs

- [x] 5.1 Add `.swiftlint.yml` and resolve any lint findings in the new code
- [x] 5.2 Add a CI workflow that runs build + full test suite + SwiftLint + coverage gate, excluding only views/app-entry/generated/platform-edge (engine never excluded) (spec: build-tooling)
- [x] 5.3 Update `README.md`: tooling install (XcodeGen, SwiftLint) + versions, generate/build/run/test commands, package-graph overview (§0.3)

## 6. Verification

- [x] 6.1 `swift test` (and the Xcode test action) green across all packages; coverage gate passes
- [x] 6.2 Fresh-checkout dry run: README commands verified — `xcodegen generate`, `./scripts/test.sh` green, `xcodebuild` build + simulator launch to the three-tab shell all succeed (Xcode at /Applications/Xcode.app via DEVELOPER_DIR)
- [x] 6.3 Run `openspec validate bootstrap-project` clean

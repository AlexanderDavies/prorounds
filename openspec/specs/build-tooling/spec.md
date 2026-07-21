# build-tooling Specification

## Purpose
TBD - created by archiving change bootstrap-project. Update Purpose after archive.
## Requirements
### Requirement: Generated Xcode project

The project SHALL be defined declaratively via XcodeGen (`project.yml`); the resulting `ProRounds.xcodeproj` SHALL be git-ignored and regenerable from a single command.

#### Scenario: Fresh checkout generates a buildable project

- **WHEN** a developer runs the documented generate command (`xcodegen generate`) on a clean checkout
- **THEN** `ProRounds.xcodeproj` is produced and the app target builds for an iOS 17+ simulator

#### Scenario: Generated project is not committed

- **WHEN** the repository is inspected
- **THEN** `ProRounds.xcodeproj` is listed in `.gitignore` and no `.xcodeproj` is tracked

### Requirement: Layered package graph enforces dependency direction

The codebase SHALL be organized into the layered SwiftPM packages of `ARCHITECTURE_GUIDE.md` §2.1, and each `Package.swift` SHALL declare only the dependencies permitted by the layering (Foundation ← Data ← Feature; Design available to Data/Feature). A lower layer SHALL NOT depend on a higher one.

#### Scenario: Illegal upward dependency fails to compile

- **WHEN** a Foundation-layer package attempts to import a Feature-layer package it does not declare as a dependency
- **THEN** the build fails

#### Scenario: Feature cannot import a sibling feature

- **WHEN** a `ProRoundsFeature*` package attempts to import another `ProRoundsFeature*` package
- **THEN** the build fails because no sibling-feature dependency is declared

### Requirement: Lint and continuous integration gate

The project SHALL include a SwiftLint configuration and a CI workflow that builds the app, runs the full test suite, and enforces a coverage gate; the timer engine SHALL never be excluded from coverage.

#### Scenario: CI fails on a lint or test regression

- **WHEN** CI runs on a change that breaks the build, fails a test, or trips a lint error
- **THEN** the CI job fails and blocks merge

#### Scenario: Coverage gate excludes only permitted targets

- **WHEN** the coverage gate is evaluated
- **THEN** views, app-entry, generated, and platform-edge code may be excluded but the timer engine is included

### Requirement: README documents build, run, and test

The `README.md` SHALL document how to install tooling, generate the project, build, run in the simulator, and run the tests.

#### Scenario: A new contributor can bootstrap from the README alone

- **WHEN** a contributor follows the README from a clean checkout
- **THEN** they can generate the project, launch the app in a simulator, and run `swift test` (or the documented test command) to green

### Requirement: Visual-regression snapshot workflow

The project SHALL support snapshot testing of design-system components on the iOS simulator via a documented command (`scripts/snapshot.sh`), using a test-only snapshot dependency that never ships in the app. CI SHALL run the snapshot suite. The macOS `swift test` logic loop SHALL remain green and unaffected (snapshot tests are guarded to platforms with UIKit).

#### Scenario: Snapshot suite runs on the simulator

- **WHEN** `scripts/snapshot.sh` is run with the iOS simulator available
- **THEN** the design-system snapshot tests execute and pass against their committed references

#### Scenario: Logic loop stays independent of the snapshot tooling

- **WHEN** `./scripts/test.sh` runs on the host
- **THEN** it builds and passes without executing the UIKit-only snapshot tests

### Requirement: Coverage gate excludes declarative view code

The coverage gate SHALL exclude the declarative `ProRoundsDesignSystem` view code from its denominator (guide §14.4), while continuing to include logic-bearing code and never excluding the timer engine.

#### Scenario: Design-system views are not counted in the gate

- **WHEN** the coverage gate computes its percentage
- **THEN** the design-system component/view files are excluded and the timer engine is included


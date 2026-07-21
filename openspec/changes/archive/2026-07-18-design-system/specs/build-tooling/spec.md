## ADDED Requirements

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

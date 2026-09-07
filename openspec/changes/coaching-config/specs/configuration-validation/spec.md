## ADDED Requirements

### Requirement: Coaching is valid only for workout types with an authored script
The validator SHALL reject a configuration that requests coaching for a workout type that has no
coach script. In v1 that means Shadow Boxing and Heavy Bag only — the two whose scripts genuinely
differ, because bag work needs a longer cadence while you recover the bag.

#### Scenario: Coaching on a scripted type is valid
- **WHEN** a Shadow Boxing or Heavy Bag configuration requests beginner coaching
- **THEN** validation SHALL report no coaching-related error

#### Scenario: Coaching on an unscripted type is rejected
- **WHEN** a Skipping, Speed Ball or Sparring configuration requests coaching
- **THEN** validation SHALL report that coaching is unavailable for that workout type

#### Scenario: Coaching off is always valid
- **WHEN** any configuration has no coaching level
- **THEN** validation SHALL report no coaching-related error, whatever its workout type

#### Scenario: The coaching error joins the others
- **WHEN** a configuration is invalid for coaching and for another reason at once
- **THEN** both violations SHALL be reported together, consistent with reporting all violations

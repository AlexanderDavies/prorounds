## ADDED Requirements

### Requirement: The coaching level round-trips through the store
The persistence record SHALL carry the coaching level, and saving then loading a configuration SHALL
preserve it exactly, including its absence.

#### Scenario: A coached configuration round-trips
- **WHEN** a configuration with beginner coaching is saved and loaded
- **THEN** it SHALL come back with beginner coaching

#### Scenario: An uncoached configuration round-trips
- **WHEN** a configuration with no coaching level is saved and loaded
- **THEN** it SHALL come back with no coaching level, not a default one

### Requirement: Existing stored configurations survive the schema change
Adding the coaching column SHALL NOT lose or corrupt records written before it existed. SwiftData is
the only copy of the user's configurations — there is no backend and no export — so a migration that
drops a record loses it permanently.

#### Scenario: A store written before the change still opens
- **WHEN** a store containing configurations saved without a coaching column is opened by the new
  schema
- **THEN** it SHALL open without error and every configuration SHALL still be present

#### Scenario: Pre-existing configurations read back as uncoached
- **WHEN** a configuration written before the coaching column is loaded
- **THEN** its coaching level SHALL be nil, and every other field SHALL be unchanged

#### Scenario: Migrated records are writable
- **WHEN** a configuration migrated from the older schema is edited and saved
- **THEN** the save SHALL succeed and the change SHALL persist

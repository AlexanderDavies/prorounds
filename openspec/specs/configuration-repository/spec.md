# configuration-repository Specification

## Purpose
TBD - created by archiving change config-data-validation. Update Purpose after archive.
## Requirements
### Requirement: Repository boundary returns domain value types

The system SHALL define a `Sendable` `ConfigurationRepository` protocol exposing domain operations — list, save (insert or update), and delete by id — that return and accept the value-type `Configuration` only. The SwiftData `@Model` entity and `ModelContext` SHALL never cross the protocol boundary; features depend on the protocol, not the concrete implementation.

#### Scenario: Callers see only domain values

- **WHEN** a caller lists or saves through the repository
- **THEN** it works entirely in terms of `Configuration`, never a SwiftData entity or context

### Requirement: Save inserts or updates by id

`save(_:)` SHALL insert a configuration that does not yet exist and update the existing record when one with the same id is already stored — never creating a duplicate.

#### Scenario: Saving a new configuration inserts it

- **WHEN** a configuration with a new id is saved into an empty store
- **THEN** listing returns exactly that one configuration

#### Scenario: Saving an existing id updates in place

- **WHEN** a stored configuration is saved again with changed fields under the same id
- **THEN** listing returns one configuration with the updated fields, not two

### Requirement: Delete by id

`delete(_:)` SHALL remove the configuration with the given id; deleting an id that is absent SHALL be a no-op (not an error).

#### Scenario: Deleting removes the configuration

- **WHEN** a stored configuration is deleted by its id
- **THEN** it no longer appears in the listing

#### Scenario: Deleting an absent id is harmless

- **WHEN** delete is called with an id that is not stored
- **THEN** the call completes without error and the store is unchanged

### Requirement: Listing is ordered most-recent-first

`all()` SHALL return configurations ordered most-recently-created-or-updated first, matching the DESIGN config-list ordering decision, using a store-internal timestamp not exposed on the domain model.

#### Scenario: Newest configuration is first

- **WHEN** two configurations are saved in sequence and then listed
- **THEN** the one saved most recently is first

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


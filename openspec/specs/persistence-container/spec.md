# persistence-container Specification

## Purpose
TBD - created by archiving change config-data-validation. Update Purpose after archive.
## Requirements
### Requirement: Single configured SwiftData container factory

The system SHALL provide one place — `ProRoundsFoundationPersistence` — that builds the SwiftData `ModelContainer`, offering a default on-disk container and an in-memory container for tests. It SHALL take the entity types as an argument so the Foundation layer holds no reference to a Data-layer entity (the composition root injects them). No feature or repository SHALL construct a container elsewhere.

#### Scenario: In-memory container for tests

- **WHEN** the in-memory factory is asked for a container for a set of entity types
- **THEN** it returns a `ModelContainer` whose store is memory-only and leaves nothing on disk

#### Scenario: On-disk container for the app

- **WHEN** the default factory is asked for a container for a set of entity types
- **THEN** it returns a `ModelContainer` backed by the on-device store

#### Scenario: Foundation layer stays generic

- **WHEN** the persistence module is inspected
- **THEN** it imports no `ProRoundsData*` module — the entity types are passed in, not referenced by name


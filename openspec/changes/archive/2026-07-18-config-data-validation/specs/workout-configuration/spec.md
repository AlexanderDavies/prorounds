## ADDED Requirements

### Requirement: Configuration has a stable identity

The `Configuration` value type SHALL carry a stable `id: UUID` and conform to `Identifiable`, so it can be persisted, updated in place, and deleted by id. The id SHALL default to a fresh value when not supplied, so existing in-memory construction (e.g. by the engine and its tests) is unaffected.

#### Scenario: A configuration keeps its id across a round-trip

- **WHEN** a configuration is created, saved, and read back
- **THEN** the read-back configuration has the same `id`

#### Scenario: Identity does not disturb existing construction

- **WHEN** a configuration is constructed without specifying an id
- **THEN** it receives a fresh unique id and its other fields and derived values are unchanged

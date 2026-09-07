## ADDED Requirements

### Requirement: Seeded generator is reproducible across machines and OS versions
The system SHALL derive coaching randomness from an explicit `SplitMix64` generator seeded by an
FNV-1a 64-bit hash of `"<configID>#<roundIndex>"`. It SHALL NOT use
`SystemRandomNumberGenerator`, whose sequence is not stable across OS versions or machines.

#### Scenario: Same identity yields the same sequence
- **WHEN** two generators are seeded with the same `configID` and `roundIndex`
- **THEN** they SHALL emit an identical sequence of values

#### Scenario: Different rounds diverge
- **WHEN** two generators share a `configID` but differ in `roundIndex`
- **THEN** they SHALL emit different sequences

#### Scenario: Matches the Python reference
- **WHEN** the generator is seeded with a `configID` and `roundIndex` used by `scripts/coach-script.py`
- **THEN** the first values emitted SHALL equal those emitted by the Python implementation for the
  same seed, verified against a committed fixture

#### Scenario: Hash is order- and encoding-stable
- **WHEN** the seed string is hashed
- **THEN** FNV-1a SHALL be applied over its UTF-8 bytes, producing the same digest regardless of
  platform string representation

### Requirement: Weighted draws are a pure function of the generator
The system SHALL implement weighted selection over a pool such that the chosen element depends only
on the pool contents, their weights, and the generator state.

#### Scenario: Weighted draw is deterministic
- **WHEN** the same pool and weights are drawn from generators in identical state
- **THEN** the same element SHALL be chosen and the generators SHALL advance identically

#### Scenario: Zero-weight entries are never chosen
- **WHEN** a pool contains an entry with weight zero
- **THEN** that entry SHALL NOT be returned by any draw

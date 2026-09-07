# deterministic-rng Specification

## Purpose
Defines the randomness coaching draws from, and why it cannot be the system generator.

`SystemRandomNumberGenerator` cannot be seeded, and its sequence is not stable across OS versions or
machines. Coaching depends on the opposite: the same workout must call the same combinations every
time it is run, on any device, after any OS upgrade. So the sequence is fixed by construction —
FNV-1a over the round's identity, then SplitMix64 — and pinned to vectors generated from the Python
reference, compared as IEEE-754 bit patterns rather than decimals so a divergence in the last
mantissa bit cannot pass unnoticed.

## Requirements
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

#### Scenario: Zero-weight entries are never chosen from a mixed pool
- **WHEN** a pool contains an entry with weight zero alongside entries with positive weight
- **THEN** the zero-weight entry SHALL NOT be returned by any draw

#### Scenario: An all-zero pool falls through to its last entry
- **WHEN** every entry in a pool has weight zero
- **THEN** the last entry SHALL be returned, matching the reference's trailing fallback — this is a
  real branch reached whenever the running total never exceeds the draw, and a port that instead
  throws or returns nothing diverges from the reference


# performance-metrics Specification

## Purpose
TBD - created by archiving change performance-chart. Update Purpose after archive.
## Requirements
### Requirement: Active-minutes series per workout type plus a total

The system SHALL aggregate sessions into time-bucketed **active-minutes** series — one per workout type that has sessions, plus a **total** series summing all types per bucket. Active minutes are a session's round time only (`Session.activeDuration`, rest/prep excluded — DESIGN §7.4). Aggregation SHALL be pure and take injected sessions (no live fetch).

#### Scenario: Per-type and total series are produced

- **WHEN** sessions of two workout types are aggregated
- **THEN** each type has a series of its active minutes over time, and a total series equals the per-bucket sum across types

#### Scenario: Active minutes exclude rest and prep

- **WHEN** a 12×3:00 session with 1:00 rest and 0:10 prep is aggregated
- **THEN** it contributes 36 active minutes (12 × 3), not the full workout time

### Requirement: Range filtering

The metrics SHALL support a range (Week / Month / All) that restricts the sessions and buckets used, so the chart can show a focused window.

#### Scenario: Range restricts the window

- **WHEN** the range is Week
- **THEN** only sessions within the last week are aggregated, bucketed within that window

### Requirement: Summary figures

The system SHALL compute summary figures for the selected range — total active minutes, session count, and total rounds completed — from the same sessions.

#### Scenario: Summary figures reflect the range's sessions

- **WHEN** the summary is computed for a range containing three sessions totalling 90 active minutes and 30 rounds
- **THEN** it reports 90 active minutes, 3 sessions, and 30 rounds


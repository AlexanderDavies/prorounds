## ADDED Requirements

### Requirement: Components are logic-free and token-driven

Every design-system component SHALL take injected, pre-formatted inputs, hold no product logic, and style itself only from tokens (no raw hex/size, no data fetch). The design system SHALL NOT import a Data or Feature module.

#### Scenario: A component renders purely from its inputs

- **WHEN** a component is given fixed inputs
- **THEN** it renders deterministically from those inputs alone, with no reference to a clock, network, or store

### Requirement: TimerRing reflects phase and progress

`TimerRing` SHALL render a circular progress arc colored by the current phase over a dim track, with a center stack of a phase badge, the timer numeral, and a small total-remaining readout. Progress SHALL be an injected fraction; the numeral SHALL be injected pre-formatted (count direction resolved by the caller, not the ring).

#### Scenario: The arc color follows the phase

- **WHEN** `TimerRing` is rendered for the round phase versus the rest phase
- **THEN** the arc uses the round phase color in one and the rest phase color in the other

#### Scenario: Progress is driven by the injected fraction

- **WHEN** `TimerRing` is given progress 0.25
- **THEN** a quarter of the ring is filled, independent of any clock

### Requirement: PhaseBadge shows the phase label

`PhaseBadge` SHALL render a pill with the phase's overline label and color (e.g. `PREPARE`, `ROUND 3 / 12`, `REST`, `DONE`), pairing color with text so it is legible without relying on color alone.

#### Scenario: Round badge shows round-of-count text

- **WHEN** `PhaseBadge` is given round 3 of 12
- **THEN** it displays "ROUND 3 / 12" in the round phase color

### Requirement: TransportControls

`TransportControls` SHALL render the play/pause primary control and the reset control, exposing tap callbacks and a paused/running state, with the reset control disabled before a workout starts.

#### Scenario: Primary control reflects running state

- **WHEN** `TransportControls` is in the running state versus paused
- **THEN** the primary control shows the pause glyph when running and the play glyph when paused

### Requirement: Button styles

The design system SHALL provide the button variants from `DESIGN.md` §6.1 — primary, secondary, tertiary, destructive, and icon — as reusable styles applying token fills, radii, and pressed/disabled states.

#### Scenario: Primary button uses the accent fill

- **WHEN** the primary button style is applied
- **THEN** the button fills with the brand accent and its label uses the on-accent color

### Requirement: ConfigCard

`ConfigCard` SHALL render a saved configuration row: workout-type icon, the effective name, a metadata line (rounds × round · rest · total), and a trailing total chip/chevron, from injected pre-formatted strings.

#### Scenario: Card shows name and metadata from inputs

- **WHEN** `ConfigCard` is given a name and a metadata line
- **THEN** it displays both, with the workout-type icon leading

### Requirement: Every component is snapshot-tested in light, dark, and Dynamic Type

Each component SHALL have snapshot tests in light and dark appearance and at a larger Dynamic Type size; a visual change that does not match the committed reference SHALL fail the build.

#### Scenario: A visual regression fails the snapshot test

- **WHEN** a component's rendered output diverges from its committed reference image
- **THEN** its snapshot test fails

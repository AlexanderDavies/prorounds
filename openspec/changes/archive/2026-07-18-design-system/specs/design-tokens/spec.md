## ADDED Requirements

### Requirement: Semantic color tokens resolve for both appearances

The design system SHALL expose the `DESIGN.md` §3 color roles as a semantic Swift API (e.g. brand accent, canvas, surfaces, text primary/secondary, phase colors, track). Each SHALL resolve to the specified value in **both** light and dark appearance. Features SHALL reference these roles, never a raw hex.

#### Scenario: The brand accent is the DESIGN red in both appearances

- **WHEN** the brand-accent token is resolved under light and again under dark
- **THEN** it is the signature red (`#E50914`) in both, per the DESIGN decisions log

#### Scenario: Canvas and text invert between appearances

- **WHEN** the canvas and primary-text tokens are resolved under dark and under light
- **THEN** dark yields a near-black canvas with near-white text, and light yields a near-white canvas with near-black text

### Requirement: Spacing, radius, and typography scales

The design system SHALL expose the `DESIGN.md` §2/§4 scales — spacing on the 8-pt grid, the radius set, and the typography roles (timer, display, title, headline, body, caption, overline) — as a semantic API. The timer numeral role SHALL use monospaced digits.

#### Scenario: Spacing tokens follow the 8-pt grid

- **WHEN** the spacing tokens are read
- **THEN** they expose the documented steps (e.g. xs = 8, md = 16, lg = 24) as points

#### Scenario: The timer type role uses monospaced digits

- **WHEN** the timer typography role is applied to changing digits
- **THEN** the glyphs are monospaced so the numeral does not reflow as digits change

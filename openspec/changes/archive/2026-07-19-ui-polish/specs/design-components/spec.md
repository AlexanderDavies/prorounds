## MODIFIED Requirements

### Requirement: Button styles

The design system SHALL provide the button variants from `DESIGN.md` §6.1 — primary, secondary, tertiary, destructive, and icon — as reusable styles applying token fills, radii, and pressed/disabled states. The primary and secondary styles SHALL include internal horizontal padding so a button sized to its content (rather than stretched full-width) keeps comfortable space around its label instead of appearing cramped.

#### Scenario: Primary button uses the accent fill

- **WHEN** the primary button style is applied
- **THEN** the button fills with the brand accent and its label uses the on-accent color

#### Scenario: A hug-content button is not cramped

- **WHEN** a primary or secondary button is sized to its content (not stretched to full width)
- **THEN** its label has horizontal padding on both sides, so it reads as a comfortable pill rather than a narrow, text-to-the-edge shape

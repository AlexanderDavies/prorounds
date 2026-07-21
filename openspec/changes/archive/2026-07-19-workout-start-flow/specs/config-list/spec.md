## MODIFIED Requirements

### Requirement: Create and edit configurations from the list

The list SHALL offer a `+` create action that opens the editor for a new configuration, and an Edit action that opens the editor for an existing configuration. The Edit action SHALL be reachable both as a **swipe** on the card and from a **long-press context menu** on the card (which also offers Delete). (The card's primary tap starts the workout — see `workout-runtime`.)

#### Scenario: Plus opens the editor for a new configuration

- **WHEN** the user taps the create action
- **THEN** the config editor opens with no existing configuration (create mode)

#### Scenario: Swipe-to-edit opens the editor for an existing configuration

- **WHEN** the user triggers the Edit action on a configuration card
- **THEN** the config editor opens populated with that configuration

#### Scenario: Context menu offers Edit for an existing configuration

- **WHEN** the user long-presses a configuration card and chooses Edit
- **THEN** the config editor opens populated with that configuration

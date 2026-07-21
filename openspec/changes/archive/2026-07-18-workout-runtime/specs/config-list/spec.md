## REMOVED Requirements

### Requirement: Navigate to create or edit

**Reason**: The card's primary tap now starts the workout (DESIGN §7.1), so it no longer opens the editor. Create/edit move to explicit affordances.

**Migration**: Create a configuration via the `+` action; edit an existing one via a swipe/Edit action; tapping a card starts its workout (see the `workout-runtime` capability).

## ADDED Requirements

### Requirement: Create and edit configurations from the list

The list SHALL offer a `+` create action that opens the editor for a new configuration, and an Edit action (a swipe on the card) that opens the editor for an existing configuration. (The card's primary tap starts the workout — see `workout-runtime`.)

#### Scenario: Plus opens the editor for a new configuration

- **WHEN** the user taps the create action
- **THEN** the config editor opens with no existing configuration (create mode)

#### Scenario: Swipe-to-edit opens the editor for an existing configuration

- **WHEN** the user triggers the Edit action on a configuration card
- **THEN** the config editor opens populated with that configuration

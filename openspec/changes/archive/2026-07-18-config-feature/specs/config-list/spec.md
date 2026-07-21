## ADDED Requirements

### Requirement: Lists saved configurations most-recent-first

The Configurations list SHALL show each saved configuration as a card with its effective name, a metadata line (rounds × round · rest), a workout-type icon, and its total time — ordered most-recent-first (from the repository). Domain models SHALL be mapped to a display model outside the view (no formatting in the view).

#### Scenario: Saved configurations appear as cards, newest first

- **WHEN** the list loads with two saved configurations
- **THEN** both appear as cards with name, metadata, and total, most-recently-saved first

### Requirement: Empty state

When there are no saved configurations, the list SHALL show an empty state prompting the user to create their first workout, with a create action.

#### Scenario: Empty state invites creating a workout

- **WHEN** the list loads with no saved configurations
- **THEN** an empty state with a "create your first workout" action is shown instead of cards

### Requirement: Delete a configuration

The list SHALL let the user delete a configuration; after deletion it SHALL no longer appear, and the change SHALL be persisted through the repository.

#### Scenario: Deleting removes the card and persists

- **WHEN** the user deletes a configuration from the list
- **THEN** its card disappears and it is gone from the repository on reload

### Requirement: Navigate to create or edit

The list SHALL offer a create action (a `+`) that opens the editor for a new configuration, and tapping a card SHALL open the editor for that configuration.

#### Scenario: Plus opens the editor for a new configuration

- **WHEN** the user taps the create action
- **THEN** the config editor opens with no existing configuration (create mode)

#### Scenario: Tapping a card opens its editor

- **WHEN** the user taps a configuration card
- **THEN** the config editor opens populated with that configuration

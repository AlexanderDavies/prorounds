# config-list Specification

## Purpose
TBD - created by archiving change config-feature. Update Purpose after archive.
## Requirements
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


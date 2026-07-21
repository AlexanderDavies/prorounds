## ADDED Requirements

### Requirement: A completed workout is saved as a session

When a workout reaches the finished phase, the app SHALL build a `Session` from the configuration and completion and save it through the `SessionRepository`. Only a naturally-completed workout SHALL be saved — leaving or resetting mid-workout SHALL save nothing.

#### Scenario: Finishing a workout saves a session

- **WHEN** a workout runs to completion
- **THEN** a session for that configuration is persisted through the repository

#### Scenario: Resetting mid-workout saves nothing

- **WHEN** a running workout is reset or left before finishing
- **THEN** no session is saved

### Requirement: A failed session save is surfaced with retry

If saving the completed session fails, the app SHALL NOT silently drop it (§10.4) — the finished screen SHALL indicate the failure and offer a Retry that attempts the save again.

#### Scenario: A save failure offers a retry

- **WHEN** saving the completed session fails
- **THEN** the finished screen shows the failure and a Retry action, and retrying attempts the save again

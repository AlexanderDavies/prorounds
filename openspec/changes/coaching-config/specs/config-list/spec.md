## ADDED Requirements

### Requirement: A coached configuration is badged with its level
The configuration card SHALL show a badge naming the coaching level, so a coached workout is
identifiable in the list without opening it. An uncoached configuration SHALL show no badge and SHALL
keep its current layout unchanged.

#### Scenario: A coached configuration shows its level
- **WHEN** a configuration with beginner coaching is listed
- **THEN** its card SHALL show a badge naming that level

#### Scenario: An uncoached configuration is unchanged
- **WHEN** a configuration with no coaching is listed
- **THEN** its card SHALL show no coaching badge and SHALL be laid out as before

#### Scenario: The badge names the level rather than only marking coaching
- **WHEN** the badge is shown
- **THEN** it SHALL carry the level's name, so a second level can be told apart from the first
  without a redesign

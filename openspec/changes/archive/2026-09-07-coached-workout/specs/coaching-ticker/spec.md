## ADDED Requirements

### Requirement: The running screen shows the current call in both conventions
The running screen SHALL display the current coaching call using both naming conventions at once —
the names form given visual priority and the numbers form above it — so the mapping is learned
passively. Where a call carries a modifier, it SHALL be shown as a third, quieter line.

#### Scenario: A punch call shows both forms
- **WHEN** a call naming punches is showing
- **THEN** both its numbers form and its names form SHALL be visible, with the names form the more
  prominent

#### Scenario: A non-punch call shows one line
- **WHEN** a call that names no punches is showing
- **THEN** its single line SHALL be shown, with no empty second line

#### Scenario: A modifier is shown separately
- **WHEN** a call carries a modifier
- **THEN** the modifier SHALL appear beneath the punches rather than being run into them

### Requirement: The ticker is a complete channel on its own
The ticker SHALL convey every call, so a user who cannot hear the coach still receives all of it.

#### Scenario: Every planned call reaches the ticker
- **WHEN** a coached round runs
- **THEN** each call that fires SHALL appear in the ticker at the moment it fires

#### Scenario: The ticker is legible to assistive technology
- **WHEN** a call is announced
- **THEN** it SHALL carry an accessible description conveying the call and any modifier as one
  phrase, rather than as disconnected fragments

### Requirement: The ticker clears when there is nothing to say
The ticker SHALL show nothing outside a coached round, and SHALL NOT retain the last call.

#### Scenario: No call shows during rest
- **WHEN** the workout is resting
- **THEN** the ticker SHALL be empty rather than holding the last call of the previous round

#### Scenario: An uncoached workout shows no ticker
- **WHEN** a configuration has no coaching
- **THEN** the running screen SHALL show no ticker area at all

### Requirement: The minimal running screen honours the preference
When the minimal preference is on, the running screen SHALL reduce to the essentials during a
coached round.

#### Scenario: Minimal hides the secondary detail
- **WHEN** the minimal preference is on during a coached round
- **THEN** the screen SHALL keep the time, the phase and the ticker, and hide the rest

#### Scenario: The preference applies without restarting
- **WHEN** the preference is changed
- **THEN** the next coached round SHALL honour it with no relaunch

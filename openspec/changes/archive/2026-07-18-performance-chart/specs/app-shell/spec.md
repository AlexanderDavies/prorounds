## MODIFIED Requirements

### Requirement: Three-tab root navigation

The app SHALL launch into a root `TabView` presenting exactly three tabs — Timer, Performance, and Settings — with Timer selected by default. The **Timer tab's root SHALL be the Configurations list** (inside a `NavigationStack`) and the **Performance tab SHALL show the performance chart**; the Settings tab SHALL show placeholder content until its feature change lands.

#### Scenario: App launches to the Timer tab

- **WHEN** the app is launched
- **THEN** a three-tab bar (Timer, Performance, Settings) is shown with the Timer tab selected and the Configurations list (or its empty state) displayed

#### Scenario: Tabs are switchable

- **WHEN** the user taps the Performance or Settings tab
- **THEN** the corresponding tab's content is displayed — the performance chart (or its empty state) for Performance — and its tab item appears selected

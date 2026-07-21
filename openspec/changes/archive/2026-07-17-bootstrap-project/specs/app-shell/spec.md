## ADDED Requirements

### Requirement: Three-tab root navigation

The app SHALL launch into a root `TabView` presenting exactly three tabs — Timer, Performance, and Settings — with Timer selected by default. Each tab SHALL show placeholder content in this change.

#### Scenario: App launches to the Timer tab

- **WHEN** the app is launched
- **THEN** a three-tab bar (Timer, Performance, Settings) is shown with the Timer tab selected

#### Scenario: Tabs are switchable

- **WHEN** the user taps the Performance or Settings tab
- **THEN** the corresponding tab's content is displayed and its tab item appears selected

### Requirement: Tab items follow the design's iconography

The tab items SHALL use the SF Symbols named in the design (`timer`, `chart.line.uptrend.xyaxis`, `gearshape`) with the labels Timer, Performance, and Settings.

#### Scenario: Correct symbols and labels render

- **WHEN** the tab bar is displayed
- **THEN** each tab shows its designated SF Symbol and label

### Requirement: App shell renders in light and dark appearance

The app shell SHALL render correctly in both light and dark system appearances.

#### Scenario: Both appearances render without layout breakage

- **WHEN** the app runs under light appearance and again under dark appearance
- **THEN** the tab bar and placeholder content render legibly in each

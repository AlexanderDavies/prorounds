import XCTest

/// End-to-end UI flow: launch with a seeded configuration, start its workout, pause, and reset.
/// Assertions are on presence/state (never timer math — that is unit-tested on the engine, §14.6).
final class WorkoutFlowUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func test_startPauseResetWorkout() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestSeed"]
        app.launch()

        // The seeded configuration appears in the list.
        let card = app.cells.firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10), "Seeded configuration card should appear")
        card.tap()

        // The workout screen opens idle (ready) with a Play control — it does not auto-start.
        let play = app.buttons["Start workout"]
        XCTAssertTrue(play.waitForExistence(timeout: 10), "Workout screen should open ready with Play")

        // Play → the control flips to Pause (running).
        play.tap()
        let pause = app.buttons["Pause workout"]
        XCTAssertTrue(pause.waitForExistence(timeout: 5), "Playing should show the pause control")

        // Pause → the control flips back to resume.
        pause.tap()
        XCTAssertTrue(play.waitForExistence(timeout: 5), "Pausing should show the resume control")

        // Reset is available.
        XCTAssertTrue(app.buttons["Reset"].exists, "Reset control should be present")
        app.buttons["Reset"].tap()
    }

    /// Switching away to another tab and back returns the Timer tab to the configuration list —
    /// not the previously-opened workout screen.
    func test_returningToTimerTabShowsTheList() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestSeed"]
        app.launch()

        let card = app.cells.firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10), "Seeded configuration card should appear")
        card.tap()
        XCTAssertTrue(app.buttons["Start workout"].waitForExistence(timeout: 10), "On the workout screen")

        // Leave to Settings, then return to Timer.
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Warning sound"].waitForExistence(timeout: 10), "On the Settings tab")
        app.tabBars.buttons["Timer"].tap()

        // Back at the configuration list (home), not the retained workout screen.
        XCTAssertTrue(card.waitForExistence(timeout: 10), "Timer tab returns to the configuration list")
        XCTAssertFalse(app.buttons["Start workout"].exists, "Should not be on the workout screen")
    }

    func test_performanceTabShows() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestSeed"] // a config, but no sessions yet
        app.launch()

        app.tabBars.buttons["Performance"].tap()
        // With no completed sessions, the Performance tab shows its empty state.
        let emptyState = app.staticTexts["Complete a workout to see your trends."]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 10), "Performance empty state should appear")
    }

    func test_settingsTabShows() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestSeed"]
        app.launch()

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Warning sound"].waitForExistence(timeout: 10),
                      "Settings screen should show the warning-sound section")
        // The appearance control switches the app theme.
        app.buttons["Light"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Appearance"].exists)
    }
}

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

/// A coached workout, end to end, against the real clock and the real bundle.
///
/// Everything else about coaching is verified against a `FakeTimeSource` in microseconds. This is
/// the one check that runs the actual composition root: the catalog really loads, the scheduler
/// really produces a plan, clips really resolve out of the bundle, and cues really fire on wall
/// time. A timer bug is invisible in a screenshot (guide §0.2), so the assertions here are about
/// the coach appearing and the workout surviving — not about timing, which is unit-tested.
final class CoachedWorkoutUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func openSeededWorkout() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestSeed"]
        app.launch()
        let card = app.cells.firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10), "Seeded configuration should appear")
        card.tap()
        return app
    }

    /// The chip is the shortcut into the same stored value the editor writes, and it is offered
    /// only while idle.
    func test_idleScreenOffersTheCoachChip() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestSeed"]
        app.launch()

        // Check the seeded level survives storage before checking the workout screen reads it —
        // otherwise a failure here cannot distinguish a bad seed from a bad view model.
        let card = app.cells.firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10), "Seeded configuration should appear")
        // The badge is announced as one phrase ("Coached, Beginner"), so match on containment
        // rather than an exact label — asserting the exact string here once cost a simulator run.
        let badge = card.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Beginner"))
        XCTAssertGreaterThan(badge.count, 0,
                             "The seeded configuration should round-trip as coached")
        card.tap()

        let chip = app.buttons["coachChip"]
        XCTAssertTrue(chip.waitForExistence(timeout: 10), "Idle coached workout should offer the chip")
        XCTAssertTrue(chip.label.contains("Beginner"), "Chip should name the stored level, got '\(chip.label)'")
    }

    /// The ticker has to appear from a real schedule — not a fixture — which means the catalog
    /// loaded, the seed produced a plan, and a clip resolved.
    func test_coachedRoundShowsACallOnTheRealClock() {
        let app = openSeededWorkout()
        let play = app.buttons["Start workout"]
        XCTAssertTrue(play.waitForExistence(timeout: 10))
        play.tap()

        // The seeded workout has a 5s prep, then the first call lands early in round 1.
        let ticker = app.otherElements["coachTicker"]
        XCTAssertTrue(ticker.waitForExistence(timeout: 30),
                      "A coaching call should appear during the first round")

        // The chip is gone once running: changing the level mid-workout would change a round's
        // plan after it began.
        XCTAssertFalse(app.buttons["coachChip"].exists, "The chip must not be offered while running")
    }

    /// Pause and resume are where a second timeline would show itself — a coaching scheduler with
    /// its own clock would keep talking through a pause, or lose its place on resume.
    func test_coachedWorkoutSurvivesPauseAndResume() {
        let app = openSeededWorkout()
        let play = app.buttons["Start workout"]
        XCTAssertTrue(play.waitForExistence(timeout: 10))
        play.tap()

        let pause = app.buttons["Pause workout"]
        XCTAssertTrue(pause.waitForExistence(timeout: 10))
        XCTAssertTrue(app.otherElements["coachTicker"].waitForExistence(timeout: 30))

        pause.tap()
        XCTAssertTrue(play.waitForExistence(timeout: 5), "Pausing should show the resume control")
        play.tap()
        XCTAssertTrue(pause.waitForExistence(timeout: 5), "Resuming should show the pause control")

        // The workout is still coherent afterwards — the reset control is reachable, meaning the
        // screen did not wedge.
        XCTAssertTrue(app.buttons["Reset"].exists)
    }

    /// Backgrounding is the case the plan cursor exists for: a resume crosses several offsets in
    /// one tick, and every one of them must still fire, once each.
    func test_coachedWorkoutSurvivesBackgrounding() {
        let app = openSeededWorkout()
        let play = app.buttons["Start workout"]
        XCTAssertTrue(play.waitForExistence(timeout: 10))
        play.tap()
        XCTAssertTrue(app.buttons["Pause workout"].waitForExistence(timeout: 10))

        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 3)
        app.activate()

        XCTAssertTrue(app.buttons["Pause workout"].waitForExistence(timeout: 10),
                      "The workout should still be running after returning from the background")
        XCTAssertTrue(app.buttons["Reset"].exists, "The screen should not have wedged")
    }
}

import XCTest

/// Run on an iOS simulator with the shared PaceLife scheme.
/// Each test uses a fresh, separate on-device store; relaunches deliberately reuse it.
/// These tests never delete or seed the user's normal application data.
final class PaceLifeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launchFreshApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment["PACE_UI_TEST_SESSION"] = UUID().uuidString
        app.launch()
        XCTAssertTrue(app.buttons["tab.today"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication,
                        file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<6 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable, "Expected control to be reachable by scrolling", file: file, line: line)
    }

    @MainActor
    private func createHabit(_ title: String, in app: XCUIApplication) {
        let add = app.buttons["addHabit"]
        reveal(add, in: app)
        add.tap()
        let name = app.textFields["habitTitle"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText(title)
        app.buttons["saveHabit"].tap()
        XCTAssertTrue(app.buttons["habit.complete.\(title)"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testHabitCompletionSurvivesRelaunchAndCanBeUndone() {
        let app = launchFreshApp()
        let title = "Read a page"
        createHabit(title, in: app)
        let completion = app.buttons["habit.complete.\(title)"]
        reveal(completion, in: app)
        XCTAssertEqual(completion.value as? String, "0")
        completion.tap()
        XCTAssertEqual(completion.value as? String, "1")

        app.terminate()
        app.launch()
        XCTAssertTrue(completion.waitForExistence(timeout: 10))
        reveal(completion, in: app)
        XCTAssertEqual(completion.value as? String, "1", "Completion must be loaded from disk")
        completion.tap()
        XCTAssertEqual(completion.value as? String, "0")
        app.terminate()
        app.launch()
        XCTAssertTrue(completion.waitForExistence(timeout: 10))
        XCTAssertEqual(completion.value as? String, "0", "Undo must also persist")
    }

    @MainActor
    func testCreatedModeActivationSurvivesRelaunch() {
        let app = launchFreshApp()
        let manage = app.buttons["manageModes"]
        reveal(manage, in: app)
        manage.tap()
        XCTAssertTrue(app.buttons["addMode"].waitForExistence(timeout: 5))
        app.buttons["addMode"].tap()
        let title = app.textFields["modeTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        title.typeText("Quiet morning")
        app.buttons["saveMode"].tap()
        let activate = app.buttons["mode.activate.Quiet morning"]
        XCTAssertTrue(activate.waitForExistence(timeout: 5))
        activate.tap()

        app.terminate()
        app.launch()
        let active = app.staticTexts["mode.active"]
        XCTAssertTrue(active.waitForExistence(timeout: 10))
        XCTAssertEqual(active.label, "Quiet morning")
    }

    @MainActor
    func testHiddenProgressWidgetSurvivesRelaunchAndCanBeRestored() {
        let app = launchFreshApp()
        app.buttons["customizeWidgets"].tap()
        let progress = app.switches["widget.progress"]
        XCTAssertTrue(progress.waitForExistence(timeout: 5))
        XCTAssertEqual(progress.value as? String, "1")
        progress.tap()
        app.buttons["saveWidgets"].tap()

        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["customizeWidgets"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.otherElements["home.progress"].exists)
        app.buttons["customizeWidgets"].tap()
        XCTAssertTrue(progress.waitForExistence(timeout: 5))
        XCTAssertEqual(progress.value as? String, "0")
        progress.tap()
        app.buttons["saveWidgets"].tap()
        XCTAssertTrue(app.otherElements["home.progress"].waitForExistence(timeout: 5))
    }


    @MainActor
    func testLanguageChangeUpdatesTabsImmediatelyAndSurvivesRelaunch() {
        let app = launchFreshApp()
        app.buttons["tab.profile"].tap()
        let language = app.buttons["language"]
        reveal(language, in: app)
        language.tap()
        let english = app.buttons["English"]
        XCTAssertTrue(english.waitForExistence(timeout: 5))
        english.tap()
        XCTAssertEqual(app.buttons["tab.today"].label, "Today")
        XCTAssertEqual(app.buttons["tab.profile"].label, "Profile")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["tab.today"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["tab.today"].label, "Today")
        app.buttons["tab.profile"].tap()
        reveal(language, in: app)
        language.tap()
        app.buttons["Русский"].tap()
        XCTAssertEqual(app.buttons["tab.today"].label, "Сегодня")
        XCTAssertEqual(app.buttons["tab.profile"].label, "Профиль")
    }

    @MainActor
    func testTabsRemainReachableAfterScrollingAndNavigation() {
        let app = launchFreshApp()
        for tab in ["development", "circles", "profile", "today"] {
            let button = app.buttons["tab.\(tab)"]
            XCTAssertTrue(button.isHittable)
            button.tap()
            app.swipeUp()
            XCTAssertTrue(button.isHittable, "Bottom dock must remain reachable while content scrolls")
        }
        // Opening and closing an editor must return to the existing root, not create another stack.
        reveal(app.buttons["addHabit"], in: app)
        app.buttons["addHabit"].tap()
        XCTAssertTrue(app.textFields["habitTitle"].waitForExistence(timeout: 5))
        app.buttons["cancelHabit"].tap()
        XCTAssertTrue(app.buttons["tab.profile"].waitForExistence(timeout: 5))
        app.buttons["tab.profile"].tap()
        XCTAssertTrue(app.buttons["tab.today"].isHittable)
    }
}

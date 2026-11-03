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
        // isHittable can be true for a sliver of a row behind the fixed bottom dock.
        // Bring the complete control into the scroll viewport before tapping it.
        let scroll: XCUIElement
        if app.scrollViews.firstMatch.exists && app.scrollViews.firstMatch.isHittable { scroll = app.scrollViews.firstMatch }
        else if app.collectionViews.firstMatch.exists && app.collectionViews.firstMatch.isHittable { scroll = app.collectionViews.firstMatch }
        else if app.tables.firstMatch.exists && app.tables.firstMatch.isHittable { scroll = app.tables.firstMatch }
        else { scroll = app }
        for attempt in 0..<12 {
            var viewport = scroll.frame.insetBy(dx: 0, dy: 12)
            let dock = app.buttons["tab.today"]
            if dock.exists && dock.isHittable {
                viewport.size.height = max(0, min(viewport.maxY, dock.frame.minY - 12) - viewport.minY)
            }
            if app.keyboards.firstMatch.exists {
                viewport.size.height = max(0, min(viewport.maxY, app.keyboards.firstMatch.frame.minY - 12) - viewport.minY)
            }
            if element.exists && element.isHittable && viewport.contains(element.frame) { return }
            if element.exists {
                if element.frame.midY < viewport.midY { scroll.swipeDown() }
                else { scroll.swipeUp() }
            } else if attempt < 6 { scroll.swipeUp() }
            else { scroll.swipeDown() }
        }
        XCTFail("Expected the whole control to be reachable in the scroll viewport.\n" + app.debugDescription, file: file, line: line)
    }

    /// SwiftUI exposes the full labelled row as the switch accessibility frame.
    /// Its center can hit only the label. Tap the trailing native switch control.
    @MainActor
    private func setSwitch(_ element: XCUIElement, to enabled: Bool,
                           file: StaticString = #filePath, line: UInt = #line) {
        let expected = enabled ? "1" : "0"
        if element.value as? String != expected {
            element.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5))
                .withOffset(CGVector(dx: -30, dy: 0)).tap()
        }
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", expected), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 3), .completed,
                       "Switch must reach the requested state", file: file, line: line)
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
        setSwitch(progress, to: false)
        XCTAssertEqual(progress.value as? String, "0", "Visibility must change before saving")
        app.buttons["saveWidgets"].tap()
        XCTAssertTrue(app.buttons["customizeWidgets"].waitForExistence(timeout: 5))
        let hidden = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: app.otherElements["home.progress"])
        XCTAssertEqual(XCTWaiter.wait(for: [hidden], timeout: 5), .completed)

        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["customizeWidgets"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.otherElements["home.progress"].exists)
        app.buttons["customizeWidgets"].tap()
        XCTAssertTrue(progress.waitForExistence(timeout: 5))
        XCTAssertEqual(progress.value as? String, "0")
        setSwitch(progress, to: true)
        XCTAssertEqual(progress.value as? String, "1", "Restoring visibility must update the draft")
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
        reveal(app.buttons["openCalendar"], in: app)
        app.buttons["openCalendar"].tap()
        XCTAssertTrue(app.buttons["closeCalendar"].waitForExistence(timeout: 5))
        app.buttons["Monat"].tap()
        app.buttons["closeCalendar"].tap()
        // Opening and closing an editor must return to the existing root, not create another stack.
        reveal(app.buttons["addHabit"], in: app)
        app.buttons["addHabit"].tap()
        XCTAssertTrue(app.textFields["habitTitle"].waitForExistence(timeout: 5))
        app.buttons["cancelHabit"].tap()
        XCTAssertTrue(app.buttons["tab.profile"].waitForExistence(timeout: 5))
        app.buttons["tab.profile"].tap()
        XCTAssertTrue(app.buttons["tab.today"].isHittable)
    }
    @MainActor
    func testRoutinePartialProgressAndPauseSurviveRelaunch() {
        let app = launchFreshApp()
        reveal(app.buttons["manageRoutines"], in: app)
        app.buttons["manageRoutines"].tap()
        app.buttons["addRoutine"].tap()
        let title = app.textFields["routineTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap(); title.typeText("Morning routine")
        let first = app.textFields.matching(identifier: "routineStepTitle").element(boundBy: 0)
        reveal(first, in: app); first.tap(); first.typeText("Stretch")
        let add = app.buttons["addRoutineStep"]
        reveal(add, in: app); add.tap()
        let second = app.textFields.matching(identifier: "routineStepTitle").element(boundBy: 1)
        reveal(second, in: app); second.tap(); second.typeText("Read")
        app.buttons["saveRoutine"].tap()
        let open = app.buttons["routine.open.Morning routine"]
        XCTAssertTrue(open.waitForExistence(timeout: 5)); open.tap()
        app.buttons["startRoutine"].tap()
        let step = app.switches["routine.step.Stretch"]
        XCTAssertTrue(step.waitForExistence(timeout: 5))
        setSwitch(step, to: true)
        XCTAssertEqual(step.value as? String, "1")
        XCTAssertEqual(app.staticTexts["routine.progress"].label, "1 / 2")
        app.buttons["pauseRoutine"].tap()
        app.terminate(); app.launch()
        reveal(app.buttons["manageRoutines"], in: app); app.buttons["manageRoutines"].tap()
        XCTAssertTrue(app.buttons["addRoutine"].waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(open.waitForExistence(timeout: 10), app.debugDescription); open.tap()
        XCTAssertEqual(app.staticTexts["routine.progress"].label, "1 / 2")
        XCTAssertFalse(step.isEnabled)
        app.buttons["pauseRoutine"].tap()
        XCTAssertTrue(step.isEnabled)
        setSwitch(app.switches["routine.step.Read"], to: true)
        XCTAssertEqual(app.staticTexts["routine.progress"].label, "2 / 2")
    }

    @MainActor
    func testManualPathMilestoneSurvivesRelaunch() {
        let app = launchFreshApp()
        app.buttons["tab.development"].tap(); app.buttons["managePaths"].tap()
        app.buttons["addPath"].tap()
        let title = app.textFields["pathTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5)); title.tap(); title.typeText("Learn Russian")
        let milestone = app.textFields["milestoneTitle"]
        reveal(milestone, in: app); milestone.tap(); milestone.typeText("Take exam")
        app.buttons["savePath"].tap()
        let open = app.buttons["path.open.Learn Russian"]
        XCTAssertTrue(open.waitForExistence(timeout: 5)); open.tap()
        let record = app.buttons["recordMilestone.Take exam"]
        reveal(record, in: app); record.tap()
        let completed = app.switches["pathEntryComplete"]
        XCTAssertTrue(completed.waitForExistence(timeout: 5)); setSwitch(completed, to: true)
        app.buttons["savePathEntry"].tap()
        XCTAssertEqual(app.staticTexts["milestone.value.Take exam"].label, "1 / 1")
        app.terminate(); app.launch()
        app.buttons["tab.development"].tap(); app.buttons["managePaths"].tap()
        XCTAssertTrue(open.waitForExistence(timeout: 5)); open.tap()
        XCTAssertEqual(app.staticTexts["milestone.value.Take exam"].label, "1 / 1")
    }

    @MainActor
    func testAdaptiveAcceptedTargetDoesNotCompleteOriginalGoal() {
        let app = launchFreshApp()
        reveal(app.buttons["addHabit"], in: app); app.buttons["addHabit"].tap()
        let name = app.textFields["habitTitle"]
        XCTAssertTrue(name.waitForExistence(timeout: 5)); name.tap(); name.typeText("Study")
        app.buttons["habitGoal"].tap(); app.buttons["Dauer"].tap()
        let target = app.textFields["habitTarget"]
        XCTAssertTrue(target.waitForExistence(timeout: 5)); target.tap()
        target.typeText(XCUIKeyboardKey.delete.rawValue + "60")
        app.buttons["saveHabit"].tap()
        reveal(app.buttons["manageAdaptive"], in: app); app.buttons["manageAdaptive"].tap()
        let propose = app.buttons["proposeAdaptive"]
        reveal(propose, in: app); propose.tap()
        let accept = app.buttons["adaptive.accept.Study"]
        reveal(accept, in: app); accept.tap()
        let record = app.buttons["adaptive.record.Study"]
        reveal(record, in: app); record.tap()
        let actual = app.textFields["actualValue"]
        XCTAssertTrue(actual.waitForExistence(timeout: 5)); actual.tap()
        actual.typeText(XCUIKeyboardKey.delete.rawValue + "30")
        app.buttons["saveProgress"].tap()
        XCTAssertEqual(app.staticTexts["adaptive.progress.Study"].label, "30 / 30")
        app.buttons["closeAdaptive"].tap()
        let completed = app.buttons["habit.complete.Study"]
        // The home may retain its previous scroll position; relaunch returns to the top.
        app.terminate(); app.launch()
        reveal(completed, in: app)
        XCTAssertEqual(completed.value as? String, "0", "30 adaptive minutes must not complete the original 60-minute goal")
        reveal(app.buttons["manageAdaptive"], in: app); app.buttons["manageAdaptive"].tap()
        XCTAssertEqual(app.staticTexts["adaptive.progress.Study"].label, "30 / 30")
    }

}

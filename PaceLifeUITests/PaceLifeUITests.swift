import XCTest

/// Run on an iOS simulator with the shared PaceLife scheme.
/// Each test uses a fresh, separate on-device store; relaunches deliberately reuse it.
/// These tests never delete or seed the user's normal application data.
final class PaceLifeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launchFreshApp(accessibilityText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        if accessibilityText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
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
        XCTAssertEqual(name.value as? String, title)
        let save = app.buttons["saveHabit"]
        XCTAssertTrue(save.isEnabled)
        save.tap()
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: save)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 10), .completed, app.debugDescription)
        // Home retains the position of its bottom add button. An offscreen habit
        // may be absent from the accessibility tree until scrolled into view.
        let completion = app.buttons["habit.complete.\(title)"]
        reveal(completion, in: app)
        XCTAssertTrue(completion.exists)
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
        app.terminate(); app.launch()
        app.buttons["tab.development"].tap(); app.buttons["managePaths"].tap(); app.buttons["addPath"].tap()
        let pathTitle = app.textFields["pathTitle"]
        XCTAssertTrue(pathTitle.waitForExistence(timeout: 5)); pathTitle.tap(); pathTitle.typeText("Routine path")
        let milestone = app.textFields["milestoneTitle"]
        reveal(milestone, in: app); milestone.tap(); milestone.typeText("Complete a morning")
        let source = app.buttons["milestoneSource"]
        reveal(source, in: app); source.tap()
        app.buttons["Morning routine · Routinen"].tap()
        app.buttons["savePath"].tap()
        let openPath = app.buttons["path.open.Routine path"]
        XCTAssertTrue(openPath.waitForExistence(timeout: 5)); openPath.tap()
        XCTAssertEqual(app.staticTexts["milestone.value.Complete a morning"].label, "1 / 1")
        app.terminate(); app.launch()
        app.buttons["tab.development"].tap(); app.buttons["managePaths"].tap()
        XCTAssertTrue(openPath.waitForExistence(timeout: 5)); openPath.tap()
        XCTAssertEqual(app.staticTexts["milestone.value.Complete a morning"].label, "1 / 1")
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
        // A native detail edge-swipe must pop the modal detail, not page the root.
        let bar = app.navigationBars["Learn Russian"]
        XCTAssertTrue(bar.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(bar.buttons["Life Paths"].exists, app.debugDescription)
        // The modal navigation controller can be inset from the application frame.
        // Start at its own leading edge, below the bar, with an actual swipe.
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let edge = origin.withOffset(CGVector(dx: bar.frame.minX + 2, dy: bar.frame.maxY + 80))
        let center = origin.withOffset(CGVector(dx: bar.frame.minX + bar.frame.width * 0.8, dy: bar.frame.maxY + 80))
        edge.press(forDuration: 0, thenDragTo: center, withVelocity: .default, thenHoldForDuration: 0)
        XCTAssertTrue(app.buttons["addPath"].waitForExistence(timeout: 5), app.debugDescription)
        app.buttons["closePaths"].tap()
        assertTab("development", in: app)
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

    @MainActor
    private func assertTab(_ name: String, in app: XCUIApplication,
                           file: StaticString = #filePath, line: UInt = #line) {
        let selected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isSelected == true"),
                                                 object: app.buttons["tab.\(name)"])
        XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 5), .completed, file: file, line: line)
    }

    @MainActor
    func testNativePagingDirectionCancellationAndVerticalScroll() {
        let app = launchFreshApp()
        let dockFrame = app.otherElements["paceDock"].frame
        app.swipeLeft(velocity: .slow)
        assertTab("development", in: app)
        XCTAssertTrue(app.buttons["managePaths"].isHittable)
        app.swipeLeft(velocity: .fast)
        assertTab("circles", in: app)
        app.swipeRight(velocity: .slow)
        assertTab("development", in: app)
        // A short, slowly released drag must settle back to the current page.
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.45))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.66, dy: 0.45))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.5)
        assertTab("development", in: app)
        app.swipeUp()
        assertTab("development", in: app)
        XCTAssertEqual(app.otherElements["paceDock"].frame.minY, dockFrame.minY, accuracy: 1)
        XCTAssertEqual(app.otherElements["paceDock"].frame.height, dockFrame.height, accuracy: 1)
        app.buttons["tab.today"].tap()
        assertTab("today", in: app)
        reveal(app.buttons["addHabit"], in: app)
        app.buttons["addHabit"].tap()
        let field = app.textFields["habitTitle"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap(); field.typeText("Paging editor")
        app.swipeLeft()
        XCTAssertTrue(app.buttons["cancelHabit"].exists)
        app.buttons["cancelHabit"].tap()
        assertTab("today", in: app)
    }

    @MainActor
    func testLargestDynamicTypeKeepsDockAndEditorReachable() {
        let app = launchFreshApp(accessibilityText: true)
        let tabs = ["today", "development", "circles", "profile"]
        let dock = app.otherElements["paceDock"]
        XCTAssertGreaterThan(dock.frame.height, 100, "The accessibility text-size override must actually enlarge the dock")
        for tab in tabs {
            let button = app.buttons["tab." + tab]
            XCTAssertTrue(button.isHittable)
            XCTAssertGreaterThanOrEqual(button.frame.width, 44)
            XCTAssertGreaterThanOrEqual(button.frame.height, 48)
            XCTAssertTrue(app.frame.contains(button.frame))
            button.tap(); assertTab(tab, in: app)
            app.swipeUp()
            XCTAssertTrue(button.isHittable)
        }
        for index in 0..<(tabs.count - 1) {
            let left = app.buttons["tab." + tabs[index]].frame
            let right = app.buttons["tab." + tabs[index + 1]].frame
            XCTAssertLessThanOrEqual(left.maxX, right.minX, "Large labels must not overlap adjacent tab targets")
        }
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "pace-profile-accessibility-xxxl-light"; attachment.lifetime = .keepAlways; add(attachment)
        app.buttons["tab.today"].tap()
        let add = app.buttons["addHabit"]
        reveal(add, in: app); add.tap()
        let title = app.textFields["habitTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap(); title.typeText("Accessible habit")
        XCTAssertTrue(app.buttons["saveHabit"].isHittable)
        XCTAssertTrue(app.buttons["cancelHabit"].isHittable)
        app.buttons["cancelHabit"].tap()
        assertTab("today", in: app)
    }

    @MainActor
    func testReferenceScreenshotsLightAndDark() {
        let app = launchFreshApp()
        for theme in ["Hell", "Dunkel"] {
            app.buttons["tab.profile"].tap()
            let picker = app.buttons["theme"]
            reveal(picker, in: app); picker.tap(); app.buttons[theme].tap()
            for tab in ["today", "development", "circles", "profile"] {
                app.buttons["tab.\(tab)"].tap(); assertTab(tab, in: app)
                let attachment = XCTAttachment(screenshot: app.screenshot())
                attachment.name = "pace-\(tab)-\(theme == "Hell" ? "light" : "dark")"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
            for (tab, open, close, name) in [
                ("today", "manageModes", "closeModes", "modes"),
                ("today", "manageAdaptive", "closeAdaptive", "adaptive"),
                ("development", "managePaths", "closePaths", "paths"),
                ("development", "manageChapters", "closeChapters", "chapters"),
                ("development", "manageExperiments", "closeExperiments", "experiments")
            ] {
                app.buttons["tab.\(tab)"].tap()
                let opener = app.buttons[open]
                reveal(opener, in: app); opener.tap()
                XCTAssertTrue(app.buttons[close].waitForExistence(timeout: 5))
                let attachment = XCTAttachment(screenshot: app.screenshot())
                attachment.name = "pace-\(name)-\(theme == "Hell" ? "light" : "dark")"
                attachment.lifetime = .keepAlways; add(attachment)
                app.buttons[close].tap()
            }
        }
    }

    @MainActor
    func testChapterMemoryEditArchiveAndRelaunch() {
        let app = launchFreshApp()
        app.buttons["tab.development"].tap()
        app.buttons["manageChapters"].tap(); app.buttons["addChapter"].tap()
        let title = app.textFields["chapterTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5)); title.tap(); title.typeText("My graduation")
        app.buttons["saveChapter"].tap()
        let open = app.buttons["chapter.open.My graduation"]
        XCTAssertTrue(open.waitForExistence(timeout: 5)); open.tap()
        let add = app.buttons["addMemory"]
        reveal(add, in: app); add.tap()
        let memory = app.textFields["memoryTitle"]
        XCTAssertTrue(memory.waitForExistence(timeout: 5)); memory.tap(); memory.typeText("Passed the exam")
        app.buttons["saveMemory"].tap()
        XCTAssertTrue(app.staticTexts["Passed the exam"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        app.buttons["tab.development"].tap(); app.buttons["manageChapters"].tap()
        XCTAssertTrue(open.waitForExistence(timeout: 5)); open.tap()
        XCTAssertTrue(app.staticTexts["Passed the exam"].waitForExistence(timeout: 5))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "pace-chapters-detail-light"; attachment.lifetime = .keepAlways; self.add(attachment)
        let archive = app.buttons["archiveChapter"]
        reveal(archive, in: app); archive.tap()
        app.terminate(); app.launch()
        app.buttons["tab.development"].tap(); app.buttons["manageChapters"].tap()
        XCTAssertFalse(open.exists)
        setSwitch(app.switches["chapterArchive"], to: true)
        XCTAssertTrue(open.waitForExistence(timeout: 5)); open.tap()
        reveal(archive, in: app); archive.tap()
        let edit = app.buttons["editChapter"]
        reveal(edit, in: app); edit.tap()
        XCTAssertTrue(title.waitForExistence(timeout: 5)); title.tap(); title.typeText(" day")
        app.buttons["saveChapter"].tap()
        app.terminate(); app.launch()
        app.buttons["tab.development"].tap(); app.buttons["manageChapters"].tap()
        XCTAssertTrue(app.buttons["chapter.open.My graduation day"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testExperimentMeasurementCorrectionAndRelaunch() {
        let app = launchFreshApp()
        app.buttons["tab.development"].tap(); app.buttons["manageExperiments"].tap(); app.buttons["addExperiment"].tap()
        let title = app.textFields["experimentTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5)); title.tap(); title.typeText("Earlier sleep")
        let metric = app.textFields["metricTitle"]
        reveal(metric, in: app); metric.tap(); metric.typeText("Energy")
        app.buttons["saveExperiment"].tap()
        let open = app.buttons["experiment.open.Earlier sleep"]
        XCTAssertTrue(open.waitForExistence(timeout: 5)); open.tap()
        app.buttons["experimentCheckIn"].tap()
        let value = app.textFields["measurement.Energy"]
        XCTAssertTrue(value.waitForExistence(timeout: 5)); value.tap(); value.typeText("7")
        app.buttons["saveCheckIn"].tap()
        app.terminate(); app.launch()
        app.buttons["tab.development"].tap(); app.buttons["manageExperiments"].tap()
        XCTAssertTrue(open.waitForExistence(timeout: 5)); open.tap(); app.buttons["experimentCheckIn"].tap()
        XCTAssertTrue(value.waitForExistence(timeout: 5)); XCTAssertEqual(value.value as? String, "7")
        value.tap(); value.typeText(XCUIKeyboardKey.delete.rawValue + "8")
        app.buttons["saveCheckIn"].tap()
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "pace-experiments-detail-light"; attachment.lifetime = .keepAlways; add(attachment)
        app.terminate(); app.launch()
        app.buttons["tab.development"].tap(); app.buttons["manageExperiments"].tap()
        XCTAssertTrue(open.waitForExistence(timeout: 5)); open.tap(); app.buttons["experimentCheckIn"].tap()
        XCTAssertTrue(value.waitForExistence(timeout: 5)); XCTAssertEqual(value.value as? String, "8")
    }

    @MainActor
    func testLocalCircleRequiresConsentAndRevocationSurvivesRelaunch() {
        let app = launchFreshApp()
        app.buttons["tab.circles"].tap(); app.buttons["addCircle"].tap()
        let title = app.textFields["circleTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5)); title.tap(); title.typeText("Study group")
        app.buttons["saveCircle"].tap()
        let open = app.buttons["circle.open.Study group"]
        reveal(open, in: app); open.tap(); app.buttons["addChallenge"].tap()
        let challengeTitle = app.textFields["challengeTitle"]
        XCTAssertTrue(challengeTitle.waitForExistence(timeout: 5)); challengeTitle.tap(); challengeTitle.typeText("Study together")
        app.buttons["saveChallenge"].tap()
        let challenge = app.buttons["challenge.open.Study together"]
        XCTAssertTrue(challenge.waitForExistence(timeout: 5)); challenge.tap()
        let record = app.buttons["recordCircleContribution"]
        reveal(record, in: app); record.tap()
        let value = app.textFields["circleContributionValue"]
        XCTAssertTrue(value.waitForExistence(timeout: 5)); value.tap(); value.typeText("30")
        let share = app.switches["shareContribution"]
        XCTAssertEqual(share.value as? String, "0", "Sharing must start disabled")
        app.buttons["saveCircleContribution"].tap()
        XCTAssertEqual(app.staticTexts["circleTotal"].label, "0")
        reveal(record, in: app); record.tap()
        XCTAssertTrue(value.waitForExistence(timeout: 5)); XCTAssertEqual(value.value as? String, "30")
        reveal(share, in: app); setSwitch(share, to: true)
        app.buttons["saveCircleContribution"].tap()
        XCTAssertEqual(app.staticTexts["circleTotal"].label, "30")
        app.terminate(); app.launch(); app.buttons["tab.circles"].tap()
        reveal(open, in: app); open.tap(); challenge.tap()
        XCTAssertEqual(app.staticTexts["circleTotal"].label, "30")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "pace-circle-challenge-light"; attachment.lifetime = .keepAlways; add(attachment)
        let revoke = app.buttons["revokeContribution"]
        reveal(revoke, in: app); revoke.tap()
        app.terminate(); app.launch(); app.buttons["tab.circles"].tap()
        reveal(open, in: app); open.tap(); challenge.tap()
        XCTAssertEqual(app.staticTexts["circleTotal"].label, "0")
    }

}

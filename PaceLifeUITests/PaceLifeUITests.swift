import XCTest

/// Run on an iOS simulator with the shared PaceLife scheme.
/// Each test uses a fresh, separate on-device store; relaunches deliberately reuse it.
/// These tests never delete or seed the user's normal application data.
final class PaceLifeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launchFreshApp(accessibilityText: Bool = false, seedDashboard: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"] + (seedDashboard ? ["--uitesting-seed-dashboard"] : [])
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
            // Only the bottom keeps a margin (dock/keyboard are subtracted below). Header
            // actions sit a few points below the top of the scroll view and are fully visible.
            var viewport = scroll.frame
            viewport.size.height = max(0, viewport.height - 12)
            let dock = app.buttons["tab.today"]
            if dock.exists && dock.isHittable {
                viewport.size.height = max(0, min(viewport.maxY, dock.frame.minY - 12) - viewport.minY)
            }
            if app.keyboards.firstMatch.exists {
                viewport.size.height = max(0, min(viewport.maxY, app.keyboards.firstMatch.frame.minY - 12) - viewport.minY)
            }
            if element.exists && element.isHittable && viewport.contains(element.frame) { return }
            if element.exists {
                let delta = viewport.midY - element.frame.midY
                if abs(delta) <= viewport.height {
                    // Large accessibility controls can be skipped repeatedly by a
                    // whole-screen fling. Move a nearby target into this viewport
                    // with a bounded drag and a slow release, keeping containment.
                    let movement = min(viewport.height * 0.4, max(-viewport.height * 0.4, delta))
                    let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
                        .withOffset(CGVector(dx: 0, dy: viewport.midY - scroll.frame.minY))
                    start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: movement)),
                                withVelocity: .slow, thenHoldForDuration: 0.1)
                } else if delta > 0 { scroll.swipeDown() }
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
        // Intel AX snapshots can themselves take longer than three seconds.
        // Wait for the same required value; do not retry or toggle a second time.
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 10), .completed,
                       "Switch must reach the requested state.\n" + element.debugDescription, file: file, line: line)
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
    func testScheduledModeStartsAutomaticallyAndManualChoiceWinsForToday() {
        let app = launchFreshApp()
        let manage = app.buttons["manageModes"]
        reveal(manage, in: app); manage.tap()
        app.buttons["addMode"].tap()
        let title = app.textFields["modeTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5)); title.tap(); title.typeText("Every day")
        for day in 1...7 {
            let chip = app.buttons["mode.schedule.\(day)"]
            reveal(chip, in: app); chip.tap()
            XCTAssertTrue(chip.isSelected, "Weekday \(day) must be selected")
        }
        app.buttons["saveMode"].tap()
        // Scheduled for today: the mode is active without pressing "Activate".
        XCTAssertFalse(app.buttons["mode.activate.Every day"].waitForExistence(timeout: 2))
        app.terminate(); app.launch()
        let active = app.staticTexts["mode.active"]
        XCTAssertTrue(active.waitForExistence(timeout: 10)); XCTAssertEqual(active.label, "Every day")
        // A manual choice overrides the schedule for the rest of the day, also after relaunch.
        reveal(app.buttons["manageModes"], in: app); app.buttons["manageModes"].tap()
        let all = app.buttons["mode.all"]
        XCTAssertTrue(all.waitForExistence(timeout: 5)); all.tap()
        XCTAssertTrue(app.buttons["mode.activate.Every day"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        XCTAssertTrue(active.waitForExistence(timeout: 10))
        XCTAssertEqual(active.label, "Alle Gewohnheiten")
    }

    @MainActor
    func testHabitReminderIsSavedListedAndCanBeDisabled() {
        let app = launchFreshApp()
        createHabit("Stretch", in: app)
        let detail = app.buttons["habit.detail.Stretch"]
        reveal(detail, in: app); detail.tap()
        let add = app.buttons["reminder.add"]
        reveal(add, in: app); add.tap()
        XCTAssertTrue(app.buttons["reminder.save"].waitForExistence(timeout: 5))
        app.buttons["reminder.save"].tap()
        let toggle = app.switches.matching(NSPredicate(format: "label BEGINSWITH %@", "Erinnerung")).firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertEqual(toggle.value as? String, "1")
        app.terminate(); app.launch()
        app.buttons["tab.profile"].tap()
        let list = app.buttons["profile.reminders"]
        reveal(list, in: app); list.tap()
        let listed = app.switches.matching(NSPredicate(format: "label BEGINSWITH %@", "Erinnerung")).firstMatch
        XCTAssertTrue(listed.waitForExistence(timeout: 5), "The reminder must survive a relaunch")
        setSwitch(listed, to: false)
        app.terminate(); app.launch()
        app.buttons["tab.profile"].tap()
        reveal(app.buttons["profile.reminders"], in: app); app.buttons["profile.reminders"].tap()
        XCTAssertTrue(listed.waitForExistence(timeout: 5))
        XCTAssertEqual(listed.value as? String, "0", "Disabling must persist")
    }

    @MainActor
    func testHiddenProgressWidgetSurvivesRelaunchAndCanBeRestored() {
        let app = launchFreshApp()
        app.buttons["customizeWidgets"].tap()
        let remove = app.buttons["widget.remove.progress"]
        XCTAssertTrue(remove.waitForExistence(timeout: 5))
        reveal(remove, in: app); remove.tap()
        let removed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: remove)
        XCTAssertEqual(XCTWaiter.wait(for: [removed], timeout: 5), .completed, "Removal must update the draft before saving")
        let save = app.buttons["saveWidgets"]
        reveal(save, in: app); save.tap()
        XCTAssertTrue(app.buttons["customizeWidgets"].waitForExistence(timeout: 5))
        let hidden = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: app.otherElements["home.progress"])
        XCTAssertEqual(XCTWaiter.wait(for: [hidden], timeout: 5), .completed)

        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["customizeWidgets"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.otherElements["home.progress"].exists)
        app.buttons["customizeWidgets"].tap()
        XCTAssertFalse(app.buttons["widget.remove.progress"].exists)
        app.buttons["addWidget"].tap()
        let add = app.buttons["widget.add.progress"]
        XCTAssertTrue(add.waitForExistence(timeout: 5)); add.tap()
        XCTAssertTrue(app.buttons["widget.remove.progress"].waitForExistence(timeout: 5), "Restoring visibility must update the draft")
        let saveAgain = app.buttons["saveWidgets"]
        reveal(saveAgain, in: app); saveAgain.tap()
        XCTAssertTrue(app.otherElements["home.progress"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testDashboardSizeAndOrderSurviveRelaunch() {
        let app = launchFreshApp()
        app.buttons["customizeWidgets"].tap()
        let size = app.buttons["widget.size.week"]
        reveal(size, in: app)
        XCTAssertEqual(size.value as? String, "Mittel")
        size.tap()
        let compact = app.buttons["Klein"]
        XCTAssertTrue(compact.waitForExistence(timeout: 5)); compact.tap()
        XCTAssertEqual(size.value as? String, "Klein")
        let streakMove = app.buttons["widget.move.streak"]
        reveal(streakMove, in: app); streakMove.tap()
        let up = app.buttons["Nach oben"]
        XCTAssertTrue(up.waitForExistence(timeout: 5)); up.tap()
        let save = app.buttons["saveWidgets"]
        reveal(save, in: app); save.tap()
        XCTAssertTrue(app.buttons["customizeWidgets"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["customizeWidgets"].waitForExistence(timeout: 10))
        app.buttons["customizeWidgets"].tap()
        let streakRemove = app.buttons["widget.remove.streak"], progressRemove = app.buttons["widget.remove.progress"]
        reveal(streakRemove, in: app)
        XCTAssertTrue(progressRemove.exists)
        XCTAssertLessThan(streakRemove.frame.minY, progressRemove.frame.minY, "The moved streak widget must stay above the progress card")
        let restoredSize = app.buttons["widget.size.week"]
        reveal(restoredSize, in: app)
        XCTAssertEqual(restoredSize.value as? String, "Klein", "The chosen widget size must be persisted")
        let done = app.buttons["saveWidgets"]
        reveal(done, in: app); done.tap()
        XCTAssertTrue(app.buttons["customizeWidgets"].waitForExistence(timeout: 5))
    }

    /// Synthetic data (DEBUG seed) so the real dashboard, statistics and calendar
    /// can be compared with the Pace reference. Not user data.
    @MainActor
    func testDashboardScreenshotsWithSyntheticData() {
        let app = launchFreshApp(seedDashboard: true)
        func capture(_ name: String) {
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
        }
        XCTAssertTrue(app.otherElements["home.progress"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["hero.completed"].label, "1", "Only the synthetic completed binary habit counts as done")
        XCTAssertTrue(app.staticTexts["mode.active"].exists)
        capture("pace-dashboard-light")
        app.swipeUp()
        capture("pace-dashboard-scrolled-light")
        app.swipeUp()
        capture("pace-dashboard-bottom-light")
        app.buttons["tab.today"].tap()
        let customize = app.buttons["customizeWidgets"]
        reveal(customize, in: app); customize.tap()
        XCTAssertTrue(app.buttons["addWidget"].waitForExistence(timeout: 5))
        capture("pace-dashboard-edit-light")
        app.buttons["saveWidgets"].tap()
        let statistics = app.buttons["openStatistics"]
        reveal(statistics, in: app); statistics.tap()
        XCTAssertTrue(app.staticTexts["statistics.total"].waitForExistence(timeout: 5))
        capture("pace-statistics-light")
        app.buttons["tab.today"].tap()
        let calendar = app.buttons["openCalendar"]
        reveal(calendar, in: app); calendar.tap()
        XCTAssertTrue(app.buttons["calendarToday"].waitForExistence(timeout: 5))
        capture("pace-calendar-light")
        app.buttons["tab.development"].tap(); app.buttons["managePaths"].tap()
        let path = app.buttons["path.open.Russisch B2"]
        XCTAssertTrue(path.waitForExistence(timeout: 5)); path.tap()
        XCTAssertTrue(app.staticTexts["milestone.value.Grammatik wiederholen"].waitForExistence(timeout: 5))
        capture("pace-path-detail-light")
        app.buttons["tab.profile"].tap()
        let dark = app.buttons["Dunkel"]
        reveal(dark, in: app); dark.tap()
        capture("pace-profile-seeded-dark")
        app.buttons["tab.today"].tap()
        assertTab("today", in: app)
        capture("pace-dashboard-dark")
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
        XCTAssertTrue(app.buttons["calendarToday"].waitForExistence(timeout: 5))
        app.buttons["Woche"].tap()
        app.buttons["Monat"].tap()
        XCTAssertTrue(app.buttons["tab.today"].isHittable, "The Pace dock stays visible on pushed pages")
        // Native back returns to the existing root without a second stack.
        let back = app.navigationBars.buttons["Heute"]
        XCTAssertTrue(back.waitForExistence(timeout: 5), app.debugDescription)
        back.tap()
        XCTAssertTrue(app.buttons["openCalendar"].waitForExistence(timeout: 5))
        // Re-selecting the current tab in the dock also returns to its root.
        app.buttons["openStatistics"].tap()
        XCTAssertTrue(app.staticTexts["statistics.total"].waitForExistence(timeout: 5))
        app.buttons["tab.today"].tap()
        XCTAssertTrue(app.buttons["openCalendar"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["statistics.total"].exists)
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
        // A native detail edge-swipe must pop the pushed detail, not page the root.
        let backToList = app.navigationBars.buttons["Life Paths"]
        XCTAssertTrue(backToList.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(backToList.isHittable, app.debugDescription)
        let bar = app.navigationBars.firstMatch
        // Start at the navigation bar's leading edge, below the bar, with an actual swipe.
        let edge = bar.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 1))
            .withOffset(CGVector(dx: 2, dy: 80))
        let center = bar.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 1))
            .withOffset(CGVector(dx: 0, dy: 80))
        XCTAssertEqual(edge.screenPoint.x, bar.frame.minX + 2, accuracy: 0.5)
        // Use the brief finger contact from the original passing gesture. A
        // zero-duration press did not reach the native recognizer's begin check.
        edge.press(forDuration: 0.05, thenDragTo: center, withVelocity: .default, thenHoldForDuration: 0)
        XCTAssertTrue(app.buttons["addPath"].waitForExistence(timeout: 5), app.debugDescription)
        assertTab("development", in: app)
        app.navigationBars.buttons["Entwicklung"].tap()
        XCTAssertTrue(app.buttons["managePaths"].waitForExistence(timeout: 5))
        assertTab("development", in: app)
    }

    @MainActor
    func testAdaptiveAcceptedTargetDoesNotCompleteOriginalGoal() {
        let app = launchFreshApp()
        reveal(app.buttons["addHabit"], in: app); app.buttons["addHabit"].tap()
        let name = app.textFields["habitTitle"]
        XCTAssertTrue(name.waitForExistence(timeout: 5)); name.tap(); name.typeText("Study")
        app.buttons["Dauer"].tap()
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
        app.navigationBars.buttons["Heute"].tap()
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
        XCTAssertLessThanOrEqual(dock.frame.height, 100, "The compact dock must not wrap tab captions into several lines")
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
        let modes = app.buttons["profile.modes"]
        reveal(modes, in: app)
        XCTAssertGreaterThan(modes.frame.height, 80, "The accessibility override must enlarge page content, while the dock stays compact")
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
            let option = app.buttons[theme]
            reveal(option, in: app); option.tap()
            for tab in ["today", "development", "circles", "profile"] {
                app.buttons["tab.\(tab)"].tap(); assertTab(tab, in: app)
                let attachment = XCTAttachment(screenshot: app.screenshot())
                attachment.name = "pace-\(tab)-\(theme == "Hell" ? "light" : "dark")"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
            for (tab, open, marker, name) in [
                ("today", "manageModes", "addMode", "modes"),
                ("today", "manageAdaptive", "proposeAdaptive", "adaptive"),
                ("development", "managePaths", "addPath", "paths"),
                ("development", "manageChapters", "addChapter", "chapters"),
                ("development", "manageExperiments", "addExperiment", "experiments")
            ] {
                app.buttons["tab.\(tab)"].tap()
                assertTab(tab, in: app)
                let opener = app.buttons[open]
                reveal(opener, in: app)
                XCTAssertTrue(opener.isHittable)
                // Give the synthetic touch a real contact interval, as in the
                // back-swipe regression. No second tap or retry masks a failure.
                opener.press(forDuration: 0.05)
                XCTAssertTrue(app.buttons[marker].waitForExistence(timeout: 10), app.debugDescription)
                XCTAssertTrue(app.buttons["tab.\(tab)"].isHittable, "The dock stays visible on pushed pages")
                let attachment = XCTAttachment(screenshot: app.screenshot())
                attachment.name = "pace-\(name)-\(theme == "Hell" ? "light" : "dark")"
                attachment.lifetime = .keepAlways; add(attachment)
                // The dock returns to the tab root; the pushed page disappears.
                app.buttons["tab.\(tab)"].tap()
                let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: app.buttons[marker])
                XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 10), .completed, app.debugDescription)
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
    func testChapterPhotoPickerCancelImportRemovalAndRelaunch() {
        let app = launchFreshApp()
        app.buttons["tab.development"].tap(); app.buttons["manageChapters"].tap()
        app.buttons["addChapter"].tap()
        let title = app.textFields["chapterTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5)); title.tap(); title.typeText("Photo test")
        app.buttons["saveChapter"].tap()
        let open = app.buttons["chapter.open.Photo test"]
        XCTAssertTrue(open.waitForExistence(timeout: 5)); open.tap()
        let picker = app.buttons["addChapterPhotos"]
        reveal(picker, in: app); picker.tap()
        let cancel = app.navigationBars.buttons.matching(NSPredicate(format: "label IN %@", ["Cancel", "Abbrechen", "Отменить", "Отмена"] as NSArray)).firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 10), app.debugDescription); cancel.tap()
        let cancelled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: cancel)
        XCTAssertEqual(XCTWaiter.wait(for: [cancelled], timeout: 10), .completed, app.debugDescription)
        let photo = app.images.matching(NSPredicate(format: "identifier BEGINSWITH %@", "chapter.photo.")).firstMatch
        let remove = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "chapter.removePhoto.")).firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5)); XCTAssertFalse(remove.exists)

        picker.tap()
        let add = app.navigationBars.buttons.matching(NSPredicate(format: "label BEGINSWITH %@ OR label BEGINSWITH %@ OR label BEGINSWITH %@", "Add", "Hinzufügen", "Добавить")).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 10), app.debugDescription)
        // scripts/test-ios.sh adds an explicitly synthetic PNG fixture to the
        // simulator's Photos library. No private or remote photos are required.
        // Older pickers expose collection-view cells; the iOS 18.x picker renders the grid
        // as images ("PXGGridLayout-Info"). Accept either, without retries or second taps.
        let cell = app.collectionViews.cells.firstMatch
        let gridImage = app.images.matching(identifier: "PXGGridLayout-Info").firstMatch
        let photoElement = gridImage.waitForExistence(timeout: 10) ? gridImage : cell
        XCTAssertTrue(photoElement.waitForExistence(timeout: 5), app.debugDescription); photoElement.tap()
        let selected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: add)
        XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 10), .completed, app.debugDescription)
        add.tap()
        // Decoding and re-encoding the picked image can take longer on Intel runners;
        // the page stays disabled while importing. The photo itself is still required.
        XCTAssertTrue(photo.waitForExistence(timeout: 30), app.debugDescription)
        XCTAssertTrue(remove.exists)
        app.terminate(); app.launch()
        app.buttons["tab.development"].tap(); app.buttons["manageChapters"].tap()
        XCTAssertTrue(open.waitForExistence(timeout: 5)); open.tap()
        XCTAssertTrue(photo.waitForExistence(timeout: 10), app.debugDescription)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "pace-chapters-photo-test-fixture-light"
        attachment.lifetime = .keepAlways; self.add(attachment)
        reveal(remove, in: app); remove.tap()
        let removed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: remove)
        XCTAssertEqual(XCTWaiter.wait(for: [removed], timeout: 10), .completed, app.debugDescription)
        XCTAssertFalse(photo.exists)
        app.terminate(); app.launch()
        app.buttons["tab.development"].tap(); app.buttons["manageChapters"].tap()
        XCTAssertTrue(open.waitForExistence(timeout: 5)); open.tap()
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        XCTAssertFalse(remove.exists); XCTAssertFalse(photo.exists)
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
        XCTAssertTrue(app.staticTexts["Gemeinsamer Fortschritt"].exists, "The total covers the shared challenge, not a personal daily goal")
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

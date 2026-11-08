import XCTest
@testable import PaceLifeCore

final class ScheduleTests: XCTestCase {
    private static var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
    private static func date(_ day: String, hour: Int = 9) -> Date {
        DayKey(rawValue: day).localDate(calendar: utc)!.addingTimeInterval(TimeInterval((hour - 12) * 3600))
    }
    private static let created = date("2026-10-01")

    func testWeeklyModesFollowTheScheduleAndManualChoicesWinForTheirDay() async throws {
        try await MainActor.run {
            var now = Self.date("2026-11-02") // Monday
            let store = try LifeStore(repository: MemoryStateRepository(), now: { now }, calendar: Self.utc)
            let work = Habit(title: "Focus", createdAt: Self.created), rest = Habit(title: "Walk", createdAt: Self.created)
            try store.saveHabit(work); try store.saveHabit(rest)
            let workday = LifeMode(title: "Workday", habitIDs: [work.id], scheduledWeekdays: [2, 3, 4, 5, 6])
            let weekend = LifeMode(title: "Weekend", habitIDs: [rest.id], scheduledWeekdays: [1, 7])
            let holiday = LifeMode(title: "Holiday", habitIDs: [rest.id])
            try store.saveMode(workday); try store.saveMode(weekend); try store.saveMode(holiday)

            XCTAssertTrue(try store.applyModeSchedule(at: now, calendar: Self.utc))
            XCTAssertEqual(store.state.activeModeID, workday.id)
            XCTAssertEqual(store.state.activations.last?.isAutomatic, true)
            XCTAssertFalse(try store.applyModeSchedule(at: now, calendar: Self.utc), "The rule is idempotent")

            // A manual choice overrides the schedule for the rest of Monday only.
            try store.activateMode(id: holiday.id, at: now.addingTimeInterval(60))
            XCTAssertEqual(store.state.modeOverrideDay?.rawValue, "2026-11-02")
            XCTAssertFalse(try store.applyModeSchedule(at: now.addingTimeInterval(120), calendar: Self.utc))
            XCTAssertEqual(store.state.activeModeID, holiday.id)
            XCTAssertNil(store.state.activations.last?.isAutomatic)

            now = Self.date("2026-11-03")
            XCTAssertTrue(try store.applyModeSchedule(at: now, calendar: Self.utc))
            XCTAssertEqual(store.state.activeModeID, workday.id)
            XCTAssertEqual(store.dueHabits(on: now, calendar: Self.utc).map(\.id), [work.id])

            // Removing every schedule ends an automatic mode, but never a manual one.
            var manualOnly = workday; manualOnly.scheduledWeekdays = nil
            var weekendOff = weekend; weekendOff.scheduledWeekdays = []
            try store.saveMode(manualOnly); try store.saveMode(weekendOff)
            now = Self.date("2026-11-04")
            XCTAssertTrue(try store.applyModeSchedule(at: now, calendar: Self.utc))
            XCTAssertNil(store.state.activeModeID)
            try store.activateMode(id: holiday.id, at: now.addingTimeInterval(60))
            now = Self.date("2026-11-05")
            XCTAssertFalse(try store.applyModeSchedule(at: now, calendar: Self.utc))
            XCTAssertEqual(store.state.activeModeID, holiday.id, "A manual choice from an earlier day stays without a schedule")
        }
    }

    func testUntouchedDaysAreFrozenWithTheirScheduledMode() async throws {
        try await MainActor.run {
            var now = Self.date("2026-11-06") // Friday
            let store = try LifeStore(repository: MemoryStateRepository(), now: { now }, calendar: Self.utc)
            let work = Habit(title: "Focus", createdAt: Self.created), rest = Habit(title: "Walk", createdAt: Self.created)
            try store.saveHabit(work); try store.saveHabit(rest)
            try store.saveMode(LifeMode(title: "Workday", habitIDs: [work.id], scheduledWeekdays: [2, 3, 4, 5, 6]))
            try store.saveMode(LifeMode(title: "Weekend", habitIDs: [rest.id], scheduledWeekdays: [1, 7]))
            try store.applyModeSchedule(at: now, calendar: Self.utc)
            XCTAssertEqual(store.state.dayPlans.last?.habitIDs, [work.id])
            // The app is not opened over the weekend; Monday's first change freezes both days.
            now = Self.date("2026-11-09")
            XCTAssertFalse(try store.applyModeSchedule(at: now, calendar: Self.utc), "Monday keeps the automatic Workday mode")
            let liveSaturday = store.state.plan(on: Self.date("2026-11-07"), today: now, calendar: Self.utc)
            XCTAssertEqual(liveSaturday?.habitIDs, [rest.id], "Uncaptured days already preview their scheduled mode")
            try store.saveHabit(Habit(title: "Read", createdAt: Self.created))
            let saturday = try XCTUnwrap(store.state.dayPlans.first { $0.day.rawValue == "2026-11-07" })
            let sunday = try XCTUnwrap(store.state.dayPlans.first { $0.day.rawValue == "2026-11-08" })
            XCTAssertEqual(saturday.habitIDs, [rest.id]); XCTAssertEqual(saturday.modeTitle, "Weekend")
            XCTAssertEqual(sunday.habitIDs, [rest.id])
            XCTAssertEqual(store.state.dayPlans.last?.modeTitle, "Workday")
            XCTAssertEqual(saturday, liveSaturday, "The frozen plan equals the earlier preview")
            // A forecast uses the schedule as well.
            let saturdayForecast = store.state.plan(on: Self.date("2026-11-14"), today: now, calendar: Self.utc)
            XCTAssertEqual(saturdayForecast?.modeTitle, "Weekend")
        }
    }

    func testRemindersValidateLimitAndDisappearWithArchivedTargets() async throws {
        try await MainActor.run {
            let store = try LifeStore(repository: MemoryStateRepository(), now: { Self.date("2026-11-02") }, calendar: Self.utc)
            let habit = Habit(title: "Read", createdAt: Self.created)
            let routine = Routine(title: "Morning", steps: [RoutineStep(title: "Stretch")], createdAt: Self.created)
            try store.saveHabit(habit); try store.saveRoutine(routine)
            let reminder = Reminder(target: .habit(habit.id), minute: 7 * 60 + 30, weekdays: [2, 4])
            try store.saveReminder(reminder)
            try store.saveReminder(Reminder(target: .routine(routine.id), minute: 6 * 60, isEnabled: false))
            XCTAssertEqual(store.state.scheduledReminders().map(\.weekday), [2, 4], "Disabled reminders are not scheduled")
            XCTAssertEqual(store.state.scheduledReminders().first?.title, "Read")
            XCTAssertEqual(store.state.scheduledReminders().first?.hour, 7)
            XCTAssertEqual(store.state.scheduledReminders().first?.minute, 30)
            XCTAssertThrowsError(try store.saveReminder(Reminder(target: .habit(habit.id), minute: 1440)))
            XCTAssertThrowsError(try store.saveReminder(Reminder(target: .habit(habit.id), minute: 60, weekdays: [])))
            XCTAssertThrowsError(try store.saveReminder(Reminder(target: .habit(UUID()), minute: 60)))
            // 9 more daily reminders would exceed the 64 pending notifications iOS allows.
            for index in 0..<8 { try store.saveReminder(Reminder(target: .habit(habit.id), minute: 600 + index)) }
            XCTAssertEqual(store.state.scheduledReminders().count, 58)
            XCTAssertThrowsError(try store.saveReminder(Reminder(target: .habit(habit.id), minute: 700)))
            XCTAssertEqual(store.state.scheduledReminders().count, 58, "A rejected reminder changes nothing")

            try store.archiveHabit(id: habit.id)
            XCTAssertTrue(store.state.reminders.allSatisfy { $0.target == .routine(routine.id) })
            XCTAssertThrowsError(try store.saveReminder(Reminder(target: .habit(habit.id), minute: 60)), "Archived habits get no new reminders")
            try store.archiveRoutine(id: routine.id)
            XCTAssertTrue(store.state.reminders.isEmpty)
        }
    }

    func testBackupDocumentsRoundTripAndRestoreAtomically() async throws {
        try await MainActor.run {
            let habit = Habit(title: "Read", createdAt: Self.created)
            let mode = LifeMode(title: "Workday", habitIDs: [habit.id], scheduledWeekdays: [2])
            let backup = LifeState(habits: [habit], modes: [mode], reminders: [Reminder(target: .habit(habit.id), minute: 480)])
            let pretty = try JSONStateRepository.encodeDocument(backup, pretty: true)
            XCTAssertEqual(try JSONStateRepository.decodeDocument(pretty), backup)

            // A schema-9 backup (no reminders yet) is migrated, not rejected.
            var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(LifeState(habits: [habit]))) as? [String: Any])
            legacy.removeValue(forKey: "reminders")
            let nine = try JSONSerialization.data(withJSONObject: ["schemaVersion": 9, "state": legacy])
            XCTAssertEqual(try JSONStateRepository.decodeDocument(nine).habits, [habit])
            XCTAssertThrowsError(try JSONStateRepository.decodeDocument(Data(#"{"schemaVersion":11,"state":{}}"#.utf8)))
            XCTAssertThrowsError(try JSONStateRepository.decodeDocument(Data("not json".utf8)))
            let missing = try JSONSerialization.data(withJSONObject: ["schemaVersion": 10, "state": legacy])
            XCTAssertThrowsError(try JSONStateRepository.decodeDocument(missing), "Schema 10 requires its reminders array")

            let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("life.json")
            defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
            let store = try LifeStore(repository: JSONStateRepository(url: url), now: { Self.date("2026-11-02") }, calendar: Self.utc)
            try store.saveHabit(Habit(title: "Old", createdAt: Self.created))
            try store.restore(backup)
            XCTAssertEqual(store.state.habits, [habit]); XCTAssertEqual(store.state.reminders, backup.reminders)
            XCTAssertEqual(try LifeStore(repository: JSONStateRepository(url: url)).state, store.state)
        }
    }

    func testModePrioritiesAreLimitedOrderedAndPartOfTheMode() async throws {
        try await MainActor.run {
            let store = try LifeStore(repository: MemoryStateRepository(), now: { Self.date("2026-11-02") }, calendar: Self.utc)
            let habits = (0..<4).map { Habit(title: "H\($0)", createdAt: Self.created) }
            for habit in habits { try store.saveHabit(habit) }
            let ids = habits.map(\.id)
            var mode = LifeMode(title: "Focus", habitIDs: Set(ids), priorityHabitIDs: [ids[2], ids[0]])
            try store.saveMode(mode); try store.activateMode(id: mode.id)
            XCTAssertEqual(store.state.activePriorityHabitIDs, [ids[2], ids[0]])
            mode.priorityHabitIDs = Array(ids)
            XCTAssertThrowsError(try store.saveMode(mode), "At most three priorities")
            mode.priorityHabitIDs = [ids[1], ids[1]]
            XCTAssertThrowsError(try store.saveMode(mode), "No duplicates")
            mode.habitIDs = [ids[0]]; mode.priorityHabitIDs = [ids[3]]
            XCTAssertThrowsError(try store.saveMode(mode), "Priorities must belong to the mode")
            XCTAssertEqual(store.state.activePriorityHabitIDs, [ids[2], ids[0]], "Rejected edits change nothing")
        }
    }
}

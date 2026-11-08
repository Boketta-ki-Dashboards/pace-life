import XCTest
@testable import PaceLifeCore

final class DayPlanTests: XCTestCase {
    private static var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
    private static func date(_ day: String, hour: Int = 9) -> Date {
        DayKey(rawValue: day).localDate(calendar: utc)!.addingTimeInterval(TimeInterval((hour - 12) * 3600))
    }
    private static let created = date("2026-10-01")

    func testTransactionsFreezeElapsedDaysFromThePreMutationState() async throws {
        try await MainActor.run {
            var now = Self.date("2026-11-02") // Monday
            let store = try LifeStore(repository: MemoryStateRepository(), now: { now }, calendar: Self.utc)
            let read = Habit(title: "Read", createdAt: Self.created)
            try store.saveHabit(read)
            XCTAssertEqual(store.state.dayPlans.map(\.day.rawValue), ["2026-11-02"])
            XCTAssertEqual(store.state.dayPlans[0].habitIDs, [read.id])

            // Two days later a new habit is created. The skipped Tuesday is frozen with the
            // unchanged earlier definitions, not with the new habit.
            now = Self.date("2026-11-04")
            let walk = Habit(title: "Walk", createdAt: Self.created)
            try store.saveHabit(walk)
            XCTAssertEqual(store.state.dayPlans.map(\.day.rawValue), ["2026-11-02", "2026-11-03", "2026-11-04"])
            XCTAssertEqual(store.state.dayPlans[1].habitIDs, [read.id])
            XCTAssertEqual(Set(store.state.dayPlans[2].habitIDs), [read.id, walk.id])

            // Removing Wednesday from Read updates only today's plan. History stays frozen.
            var changed = read; changed.weekdays = [2]
            try store.saveHabit(changed)
            XCTAssertEqual(store.state.dayPlans[2].habitIDs, [walk.id])
            XCTAssertEqual(store.state.dayPlans[0].habitIDs, [read.id])
            XCTAssertEqual(store.state.dayPlans[1].habitIDs, [read.id])
            let tuesday = store.overview(on: Self.date("2026-11-03"), today: now, calendar: Self.utc)
            XCTAssertEqual(tuesday.plannedHabits?.map(\.id), [read.id], "Calendar history must use the frozen plan")
        }
    }

    func testClockMovingBackwardsNeverRewritesStoredPlans() async throws {
        try await MainActor.run {
            var now = Self.date("2026-11-05")
            let store = try LifeStore(repository: MemoryStateRepository(), now: { now }, calendar: Self.utc)
            try store.saveHabit(Habit(title: "Read", createdAt: Self.created))
            let stored = store.state.dayPlans
            now = Self.date("2026-11-01")
            try store.saveHabit(Habit(title: "Walk", createdAt: Self.created))
            XCTAssertEqual(store.state.dayPlans, stored)
        }
    }

    func testDeletedModeKeepsItsHistoricalTitleAndValidates() async throws {
        try await MainActor.run {
            var now = Self.date("2026-11-02")
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("life.json")
            defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
            let store = try LifeStore(repository: JSONStateRepository(url: url), now: { now }, calendar: Self.utc)
            let read = Habit(title: "Read", createdAt: Self.created), walk = Habit(title: "Walk", createdAt: Self.created)
            try store.saveHabit(read); try store.saveHabit(walk)
            let mode = LifeMode(title: "Workday", habitIDs: [read.id])
            try store.saveMode(mode); try store.activateMode(id: mode.id, at: now)
            XCTAssertEqual(store.state.dayPlans.last?.habitIDs, [read.id])
            XCTAssertEqual(store.state.dayPlans.last?.modeTitle, "Workday")
            now = Self.date("2026-11-03")
            try store.deleteMode(id: mode.id, at: now)
            let monday = try XCTUnwrap(store.state.dayPlans.first { $0.day.rawValue == "2026-11-02" })
            XCTAssertEqual(monday.modeID, mode.id); XCTAssertEqual(monday.modeTitle, "Workday")
            XCTAssertEqual(Set(store.state.dayPlans.last?.habitIDs ?? []), [read.id, walk.id])
            XCTAssertNil(store.state.dayPlans.last?.modeID)
            let restored = try LifeStore(repository: JSONStateRepository(url: url), now: { now }, calendar: Self.utc)
            XCTAssertEqual(restored.state, store.state)
        }
    }

    func testStreakRulesForRestUnknownMissedAndOpenDays() {
        let read = Habit(title: "Read", createdAt: Self.created)
        func done(_ day: String) -> HabitCompletion {
            HabitCompletion(habitID: read.id, day: DayKey(rawValue: day), timeZoneID: "UTC", actualValue: 1, targetSnapshot: 1, goalTypeSnapshot: .binary)
        }
        func plan(_ day: String, _ ids: [UUID]) -> DayPlanSnapshot { DayPlanSnapshot(day: DayKey(rawValue: day), habitIDs: ids, routineIDs: []) }
        var state = LifeState(habits: [read],
                              completions: [done("2026-10-30"), done("2026-11-01"), done("2026-11-02"), done("2026-11-04")],
                              dayPlans: [plan("2026-10-30", [read.id]), plan("2026-10-31", [read.id]), plan("2026-11-01", [read.id]),
                                         plan("2026-11-02", [read.id]), plan("2026-11-03", []), plan("2026-11-04", [read.id])])
        // 31 Oct missed; 3 Nov is a rest day; today (5 Nov) is still open.
        var streak = state.lifeStreak(today: Self.date("2026-11-05"), calendar: Self.utc)
        XCTAssertEqual(streak.current, 3)
        XCTAssertFalse(streak.todayCompleted)
        XCTAssertEqual(streak.longest, 3)
        XCTAssertEqual(streak.longestStart?.rawValue, "2026-11-01")
        XCTAssertEqual(streak.longestEnd?.rawValue, "2026-11-04")

        state.completions.append(done("2026-11-05"))
        streak = state.lifeStreak(today: Self.date("2026-11-05"), calendar: Self.utc)
        XCTAssertEqual(streak.current, 4); XCTAssertTrue(streak.todayCompleted); XCTAssertEqual(streak.longest, 4)

        // A day before the first snapshot is unknown: it ends the walk instead of counting as missed.
        let unknown = state.summary(on: Self.date("2026-10-29"), today: Self.date("2026-11-05"), calendar: Self.utc)
        XCTAssertNil(unknown.plannedHabitIDs); XCTAssertNil(unknown.progress); XCTAssertFalse(unknown.goalReached)
        let rest = state.summary(on: Self.date("2026-11-03"), today: Self.date("2026-11-05"), calendar: Self.utc)
        XCTAssertTrue(rest.isRestDay); XCTAssertFalse(rest.goalReached)
        let future = state.summary(on: Self.date("2026-11-06"), today: Self.date("2026-11-05"), calendar: Self.utc)
        XCTAssertTrue(future.isForecast); XCTAssertFalse(future.goalReached)
    }

    func testPartialDurationProgressAndUncapturedGapDaysMatchTheNextSnapshot() {
        let study = Habit(title: "Study", goalType: .duration, target: 60, createdAt: Self.created)
        let stretch = Habit(title: "Stretch", createdAt: Self.created)
        let state = LifeState(habits: [study, stretch],
                              completions: [HabitCompletion(habitID: study.id, day: DayKey(rawValue: "2026-11-04"), timeZoneID: "UTC", actualValue: 30, targetSnapshot: 60, goalTypeSnapshot: .duration)],
                              dayPlans: [DayPlanSnapshot(day: DayKey(rawValue: "2026-11-02"), habitIDs: [study.id], routineIDs: [])])
        // 4 Nov lies after the newest snapshot: the live plan equals what the next transaction freezes.
        let summary = state.summary(on: Self.date("2026-11-04"), today: Self.date("2026-11-05"), calendar: Self.utc)
        XCTAssertEqual(Set(summary.plannedHabitIDs ?? []), [study.id, stretch.id])
        XCTAssertEqual(summary.progress ?? -1, 0.25, accuracy: 0.0001)
        XCTAssertEqual(summary.plannedCompletedCount, 0)
        var captured = state
        captured.captureDayPlans(previous: state, now: Self.date("2026-11-05"), calendar: Self.utc)
        XCTAssertEqual(captured.dayPlans.first { $0.day.rawValue == "2026-11-04" }?.habitIDs, summary.plannedHabitIDs)
    }

    func testSchemaEightDocumentMigratesToNineWithoutLosingWidgetChoices() async throws {
        try await MainActor.run {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appendingPathComponent("life.json")
            let habit = Habit(title: "Read", createdAt: Self.created)
            let original = LifeState(habits: [habit], settings: AppSettings(theme: .dark, language: .en))
            var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
            json.removeValue(forKey: "dayPlans")
            var settings = try XCTUnwrap(json["settings"] as? [String: Any]); settings.removeValue(forKey: "displayName"); json["settings"] = settings
            json["widgets"] = [["kind": "habits", "isVisible": true], ["kind": "adaptive", "isVisible": true], ["kind": "progress", "isVisible": false],
                               ["kind": "mode", "isVisible": false], ["kind": "routines", "isVisible": true], ["kind": "paths", "isVisible": false]]
            let data = try JSONSerialization.data(withJSONObject: ["schemaVersion": 8, "state": json]); try data.write(to: url)

            let repo = JSONStateRepository(url: url)
            let loaded = try repo.load()
            XCTAssertEqual(try Data(contentsOf: url), data, "Reading never rewrites the document")
            XCTAssertEqual(loaded.habits, [habit]); XCTAssertTrue(loaded.dayPlans.isEmpty)
            XCTAssertNil(loaded.settings.displayName); XCTAssertEqual(loaded.settings.language, .en)
            let legacy: [HomeWidgetKind] = [.habits, .adaptive, .progress, .mode, .routines, .paths]
            XCTAssertEqual(loaded.widgets.filter { legacy.contains($0.kind) }.map(\.kind), legacy)
            XCTAssertEqual(loaded.widgets.filter { legacy.contains($0.kind) }.map(\.isVisible), [true, true, false, false, true, false])
            XCTAssertEqual(loaded.widgets.map(\.kind), [.habits, .adaptive, .overview, .progress, .streak, .week, .mode, .routines, .paths, .calendar, .circles, .experiments, .chapters])

            var resized = loaded; resized.widgets[0].size = .large
            try repo.save(resized)
            let envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
            XCTAssertEqual(envelope["schemaVersion"] as? Int, JSONStateRepository.currentSchemaVersion)
            XCTAssertEqual(try JSONStateRepository(url: url).load(), resized)

            // A schema-9 document without day plans is not silently accepted as complete.
            var nine = json; nine["widgets"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(HomeWidgetPreference.defaultLayout))
            let broken = try JSONSerialization.data(withJSONObject: ["schemaVersion": 9, "state": nine]); try broken.write(to: url)
            XCTAssertThrowsError(try JSONStateRepository(url: url).load())
            XCTAssertEqual(try Data(contentsOf: url), broken)
        }
    }

    func testInvalidDayPlansAreRejected() {
        let habit = Habit(title: "Read", createdAt: Self.created)
        let day = DayKey(rawValue: "2026-11-02")
        XCTAssertThrowsError(try LifeState(habits: [habit], dayPlans: [DayPlanSnapshot(day: day, habitIDs: [UUID()], routineIDs: [])]).validate())
        XCTAssertThrowsError(try LifeState(habits: [habit], dayPlans: [DayPlanSnapshot(day: day, habitIDs: [], routineIDs: []),
                                                                        DayPlanSnapshot(day: day, habitIDs: [habit.id], routineIDs: [])]).validate())
        XCTAssertThrowsError(try LifeState(habits: [habit], dayPlans: [DayPlanSnapshot(day: day, habitIDs: [], routineIDs: [], modeID: UUID())]).validate())
        XCTAssertNoThrow(try LifeState(habits: [habit], dayPlans: [DayPlanSnapshot(day: day, habitIDs: [habit.id], routineIDs: [], modeID: UUID(), modeTitle: "Gone")]).validate())
    }
}

import Foundation
import XCTest
@testable import PaceLifeCore

final class LifeStoreTests: XCTestCase {
    private static func calendar(_ zone: String = "Europe/Berlin") -> Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(identifier: zone)!
        return result
    }
    private static func date(_ iso: String) -> Date { ISO8601DateFormatter().date(from: iso)! }

    func testHabitCreationValidationAndArchiveRetainsHistory() async throws {
        try await MainActor.run {
            let store = try LifeStore(repository: MemoryStateRepository())
            let now = Self.date("2026-10-30T12:00:00Z")
            let habit = Habit(title: "  Walk  ", createdAt: now)
            try store.saveHabit(habit)
            XCTAssertEqual(store.state.habits[0].title, "Walk")
            try store.record(habitID: habit.id, value: 1, on: now)
            try store.archiveHabit(id: habit.id)
            XCTAssertTrue(store.dueHabits(on: now).isEmpty)
            XCTAssertEqual(store.state.completions.count, 1)
            XCTAssertThrowsError(try store.saveHabit(Habit(title: " ")))
            XCTAssertThrowsError(try store.saveHabit(Habit(title: "x", target: 0)))
            XCTAssertThrowsError(try store.saveHabit(Habit(title: "x", weekdays: [])))
            XCTAssertThrowsError(try store.saveHabit(Habit(title: "x", weekdays: [8])))
            XCTAssertThrowsError(try store.saveHabit(Habit(title: "x", goalType: .count, target: 2.5)))
        }
    }

    func testCompletionsDeduplicateAndKeepOriginalTargetAfterGoalEdit() async throws {
        try await MainActor.run {
            let store = try LifeStore(repository: MemoryStateRepository())
            let now = Self.date("2026-10-30T12:00:00Z")
            var habit = Habit(title: "Read", goalType: .count, target: 10, createdAt: now)
            try store.saveHabit(habit)
            try store.record(habitID: habit.id, value: 2, on: now)
            let completionID = store.state.completions[0].id
            habit.target = 4
            try store.saveHabit(habit)
            try store.record(habitID: habit.id, value: 4, on: now.addingTimeInterval(300))
            XCTAssertEqual(store.state.completions.count, 1)
            XCTAssertEqual(store.state.completions[0].id, completionID)
            XCTAssertEqual(store.state.completions[0].targetSnapshot, 10)
            XCTAssertEqual(store.progress(on: now), 0.4, accuracy: 0.001)
            XCTAssertFalse(store.state.completions[0].isComplete)
            try store.record(habitID: habit.id, value: 10, on: now)
            XCTAssertTrue(store.state.completions[0].isComplete)
        }
    }

    func testGoalTypeSnapshotSurvivesEditAndReset() async throws {
        try await MainActor.run {
            let store = try LifeStore(repository: MemoryStateRepository())
            let now = Self.date("2026-10-30T12:00:00Z")
            var habit = Habit(title: "Read", goalType: .duration, target: 30, createdAt: now)
            try store.saveHabit(habit)
            try store.record(habitID: habit.id, value: 12.5, on: now)
            habit.goalType = .binary; habit.target = 1
            try store.saveHabit(habit)
            try store.record(habitID: habit.id, value: 0, on: now)
            XCTAssertEqual(store.state.completions[0].targetSnapshot, 30)
            XCTAssertEqual(store.state.completions[0].goalTypeSnapshot, .duration)
            try store.record(habitID: habit.id, value: 30, on: now)
            XCTAssertTrue(store.state.completions[0].isComplete)
            let tomorrow = Self.calendar().date(byAdding: .day, value: 1, to: now)!
            try store.record(habitID: habit.id, value: 1, on: tomorrow)
            XCTAssertEqual(store.state.completions.last?.goalTypeSnapshot, .binary)
        }
    }

    func testInvalidValuesDoNotMutate() async throws {
        try await MainActor.run {
            let store = try LifeStore(repository: MemoryStateRepository())
            let now = Date()
            let habit = Habit(title: "Water", createdAt: now)
            try store.saveHabit(habit)
            for value in [-1.0, 0.5, 2, .nan, .infinity] {
                XCTAssertThrowsError(try store.record(habitID: habit.id, value: value, on: now))
            }
            XCTAssertTrue(store.state.completions.isEmpty)
        }
    }

    func testModesFilterHabitsWithoutChangingHistoryAndDeletionClosesActivation() async throws {
        try await MainActor.run {
            let store = try LifeStore(repository: MemoryStateRepository())
            let now = Self.date("2026-10-30T12:00:00Z")
            let a = Habit(title: "A", createdAt: now), b = Habit(title: "B", createdAt: now)
            try store.saveHabit(a); try store.saveHabit(b)
            try store.record(habitID: a.id, value: 1, on: now)
            let original = store.state.completions
            var mode = LifeMode(title: "Rest", habitIDs: [b.id])
            try store.saveMode(mode)
            try store.activateMode(id: mode.id, at: now)
            try store.activateMode(id: mode.id, at: now)
            XCTAssertEqual(store.state.activations.count, 1)
            XCTAssertEqual(store.dueHabits(on: now).map(\.id), [b.id])
            mode.title = "Recovery"; try store.saveMode(mode)
            XCTAssertEqual(store.state.activations.first?.titleSnapshot, "Rest")
            try store.deleteMode(id: mode.id, at: now.addingTimeInterval(100))
            XCTAssertNil(store.state.activeModeID)
            XCTAssertNotNil(store.state.activations.first?.end)
            XCTAssertEqual(store.dueHabits(on: now).count, 2)
            XCTAssertEqual(store.state.completions, original)
        }
    }

    func testEmptyModeAndInvalidMode() async throws {
        try await MainActor.run {
            let store = try LifeStore(repository: MemoryStateRepository())
            let mode = LifeMode(title: "Pause")
            try store.saveMode(mode); try store.activateMode(id: mode.id)
            XCTAssertTrue(store.dueHabits().isEmpty)
            XCTAssertEqual(store.progress(), 0)
            XCTAssertThrowsError(try store.activateMode(id: UUID()))
            XCTAssertThrowsError(try store.saveMode(LifeMode(title: "Invalid", habitIDs: [UUID()])))
        }
    }

    func testPersistenceRoundTripIncludesOrderVisibilitySettingsAndModes() async throws {
        try await MainActor.run {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: directory) }
            let url = directory.appendingPathComponent("state.json")
            let store = try LifeStore(repository: JSONStateRepository(url: url))
            let now = Date(), habit = Habit(title: "Stretch", goalType: .duration, target: 15)
            try store.saveHabit(habit)
            let mode = LifeMode(title: "Weekend", habitIDs: [habit.id])
            try store.saveMode(mode); try store.activateMode(id: mode.id)
            try store.record(habitID: habit.id, value: 8, on: now)
            let widgets = [HomeWidgetPreference(kind: .habits), HomeWidgetPreference(kind: .progress, isVisible: false), HomeWidgetPreference(kind: .mode)]
            try store.setWidgets(widgets)
            try store.setSettings(AppSettings(theme: .dark, language: .ru))
            let restored = try LifeStore(repository: JSONStateRepository(url: url))
            XCTAssertEqual(restored.state, store.state)
            XCTAssertEqual(restored.state.widgets, widgets)
            XCTAssertThrowsError(try store.setWidgets([HomeWidgetPreference(kind: .mode)]))
        }
    }

    func testFailedWriteRollsBackMemory() async throws {
        try await MainActor.run {
            let repository = FailingRepository()
            let store = try LifeStore(repository: repository)
            XCTAssertThrowsError(try store.saveHabit(Habit(title: "Never persisted")))
            XCTAssertTrue(store.state.habits.isEmpty)
        }
    }

    func testCorruptionAndFutureSchemaAreNotOverwritten() async throws {
        try await MainActor.run {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: directory) }
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appendingPathComponent("state.json")
            for content in ["broken", "{\"schemaVersion\":99,\"state\":{}}"] {
                try Data(content.utf8).write(to: url)
                XCTAssertThrowsError(try LifeStore(repository: JSONStateRepository(url: url)))
                XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), content)
            }
        }
    }

    func testDuplicatePersistedCompletionsRejected() async throws {
        try await MainActor.run {
            let habit = Habit(title: "A")
            let completion = HabitCompletion(habitID: habit.id, day: DayKey(date: Date()), timeZoneID: "UTC", actualValue: 1, targetSnapshot: 1, goalTypeSnapshot: .binary)
            let duplicate = HabitCompletion(habitID: habit.id, day: completion.day, timeZoneID: "UTC", actualValue: 1, targetSnapshot: 1, goalTypeSnapshot: .binary)
            XCTAssertThrowsError(try LifeStore(repository: MemoryStateRepository(state: LifeState(habits: [habit], completions: [completion, duplicate]))))
        }
    }

    func testDSTCivilDaysAndLocalMidnight() async {
        await MainActor.run {
            let berlin = Self.calendar()
            // Both occurrences of 02:30 during fall-back belong to the same day.
            XCTAssertEqual(DayKey(date: Self.date("2026-10-25T00:30:00Z"), calendar: berlin), DayKey(date: Self.date("2026-10-25T01:30:00Z"), calendar: berlin))
            XCTAssertEqual(DayKey(date: Self.date("2026-03-29T00:30:00Z"), calendar: berlin).rawValue, "2026-03-29")
            XCTAssertEqual(DayKey(date: Self.date("2026-03-29T01:30:00Z"), calendar: berlin).rawValue, "2026-03-29")
            XCTAssertNotEqual(DayKey(date: Self.date("2026-10-29T22:59:00Z"), calendar: berlin), DayKey(date: Self.date("2026-10-29T23:00:00Z"), calendar: berlin))
            XCTAssertEqual(DayKey(date: Self.date("2026-10-29T23:00:00Z"), calendar: berlin).rawValue, "2026-10-30")
        }
    }

    func testTimeZoneChangeDoesNotDuplicateSameCivilDate() async throws {
        try await MainActor.run {
            let store = try LifeStore(repository: MemoryStateRepository())
            let created = Self.date("2026-10-20T00:00:00Z")
            let habit = Habit(title: "A", createdAt: created)
            try store.saveHabit(habit)
            try store.record(habitID: habit.id, value: 1, on: Self.date("2026-10-30T12:00:00Z"), calendar: Self.calendar())
            try store.record(habitID: habit.id, value: 0, on: Self.date("2026-10-30T12:00:00Z"), calendar: Self.calendar("America/New_York"))
            XCTAssertEqual(store.state.completions.count, 1)
            XCTAssertEqual(store.state.completions[0].timeZoneID, "Europe/Berlin")
        }
    }

    func testFrequencyAndStreakAcrossDSTUsesCalendarDays() async throws {
        try await MainActor.run {
            let store = try LifeStore(repository: MemoryStateRepository())
            let berlin = Self.calendar()
            let habit = Habit(title: "A", createdAt: Self.date("2026-10-23T12:00:00Z"))
            try store.saveHabit(habit)
            for stamp in ["2026-10-23T12:00:00Z", "2026-10-24T12:00:00Z", "2026-10-25T12:00:00Z"] {
                try store.record(habitID: habit.id, value: 1, on: Self.date(stamp), calendar: berlin)
            }
            XCTAssertEqual(store.currentStreak(habitID: habit.id, on: Self.date("2026-10-26T12:00:00Z"), calendar: berlin), 3)
            XCTAssertEqual(store.currentStreak(habitID: habit.id, on: Self.date("2026-10-27T12:00:00Z"), calendar: berlin), 0)
            let monday = Habit(title: "Monday", weekdays: [2], createdAt: Self.date("2026-10-23T12:00:00Z"))
            try store.saveHabit(monday)
            XCTAssertFalse(monday.isDue(on: Self.date("2026-10-25T12:00:00Z"), calendar: berlin))
            XCTAssertTrue(monday.isDue(on: Self.date("2026-10-26T12:00:00Z"), calendar: berlin))
            XCTAssertFalse(monday.isDue(on: Self.date("2026-10-19T12:00:00Z"), calendar: berlin))
        }
    }

    func testExternalServicesAreExplicitlyUnavailable() async {
        await MainActor.run {
            XCTAssertEqual(UnavailablePaceServices().availability, .unavailable)
        }
    }

    func testCorruptSnapshotsAndImpossibleDatesAreRejected() async throws {
        try await MainActor.run {
            let habit = Habit(title: "A")
            let cases: [(Double, Double, GoalType, String)] = [
                (1, 2, .binary, "2026-10-30"), (0.5, 1, .binary, "2026-10-30"),
                (1.5, 3, .count, "2026-10-30"), (1, 3.5, .count, "2026-10-30"),
                (1, 1, .binary, "2026-02-30"), (1, 1, .binary, "2026-13-01")
            ]
            for (actual, target, type, day) in cases {
                let record = HabitCompletion(habitID: habit.id, day: DayKey(rawValue: day), timeZoneID: "UTC", actualValue: actual, targetSnapshot: target, goalTypeSnapshot: type)
                XCTAssertThrowsError(try LifeStore(repository: MemoryStateRepository(state: LifeState(habits: [habit], completions: [record]))))
            }
        }
    }

    func testCorruptActivationStateIsRejected() async throws {
        try await MainActor.run {
            let now = Date(), mode = LifeMode(title: "A")
            let open = ModeActivation(modeID: mode.id, titleSnapshot: "A", start: now)
            XCTAssertThrowsError(try LifeStore(repository: MemoryStateRepository(state: LifeState(modes: [mode], activations: [open]))))
            XCTAssertThrowsError(try LifeStore(repository: MemoryStateRepository(state: LifeState(modes: [mode], activeModeID: mode.id))))
            let backwards = ModeActivation(modeID: mode.id, titleSnapshot: "A", start: now, end: now.addingTimeInterval(-1))
            XCTAssertThrowsError(try LifeStore(repository: MemoryStateRepository(state: LifeState(modes: [mode], activations: [backwards]))))
            // A removed mode can legitimately remain in closed history through its title snapshot.
            let closed = ModeActivation(modeID: mode.id, titleSnapshot: "A", start: now, end: now)
            XCTAssertNoThrow(try LifeStore(repository: MemoryStateRepository(state: LifeState(activations: [closed]))))
        }
    }
}

@MainActor private final class FailingRepository: StateRepository {
    enum Failure: Error { case diskFull }
    func load() throws -> LifeState { LifeState() }
    func save(_ state: LifeState) throws { throw Failure.diskFull }
}

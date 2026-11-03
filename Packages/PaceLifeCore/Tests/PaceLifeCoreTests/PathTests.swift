import Foundation
import XCTest
@testable import PaceLifeCore

final class PathTests: XCTestCase {
    private static let now = ISO8601DateFormatter().date(from: "2026-11-03T12:00:00Z")!
    func testHabitContributionsCorrectWithoutDuplicationAndKeepFrozenUnitsAfterEdit() async throws {
        try await MainActor.run {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            let url = folder.appendingPathComponent("life.json")
            let store = try LifeStore(repository: JSONStateRepository(url: url))
            var habit = Habit(title: "Learn", goalType: .duration, target: 60, createdAt: Self.now)
            try store.saveHabit(habit)
            let milestone = PathMilestone(title: "100 hours", goalType: .duration, target: 6000, habitID: habit.id)
            let exam = PathMilestone(title: "Exam")
            let path = LifePath(title: "Russian B2", startDay: DayKey(date: Self.now), milestones: [milestone, exam])
            try store.savePath(path)
            try store.record(habitID: habit.id, value: 45, on: Self.now)
            XCTAssertEqual(store.state.milestoneValue(milestone, in: path), 45)
            XCTAssertEqual(store.state.milestoneValue(milestone, in: path), 45)
            try store.record(habitID: habit.id, value: 30, on: Self.now)
            XCTAssertEqual(store.state.milestoneValue(milestone, in: path), 30)
            habit.target = 1; habit.goalType = .binary; try store.saveHabit(habit)
            try store.record(habitID: habit.id, value: 1, on: Self.now.addingTimeInterval(86400))
            XCTAssertEqual(store.state.milestoneValue(milestone, in: path), 30, "A different unit must never be counted as minutes")
            try store.archiveHabit(id: habit.id)
            let restored = try LifeStore(repository: JSONStateRepository(url: url))
            XCTAssertEqual(restored.state.milestoneValue(milestone, in: path), 30)
            XCTAssertEqual(restored.state.pathProgress(path), 0.0025, accuracy: 0.00001)
            XCTAssertThrowsError(try restored.setPathStatus(id: path.id, status: .completed, on: Self.now))
            XCTAssertThrowsError(try restored.recordPathEntry(milestoneID: milestone.id, value: 10, on: Self.now))
            try restored.recordPathEntry(milestoneID: exam.id, value: 1, on: Self.now)
            try restored.recordPathEntry(milestoneID: exam.id, value: 0, on: Self.now)
            XCTAssertEqual(restored.state.pathEntries.count, 1)
            XCTAssertEqual(restored.state.milestoneValue(exam, in: path), 0)
        }
    }
    func testPathCompletionReopensAfterActualWorkCorrectionAndArchivePreservesEntries() async throws {
        try await MainActor.run {
            let store = try LifeStore(repository: MemoryStateRepository())
            let milestone = PathMilestone(title: "Pages", goalType: .count, target: 10)
            let path = LifePath(title: "Read", startDay: DayKey(date: Self.now), milestones: [milestone])
            try store.savePath(path)
            try store.recordPathEntry(milestoneID: milestone.id, value: 10, on: Self.now)
            try store.setPathStatus(id: path.id, status: .completed, on: Self.now)
            XCTAssertEqual(store.state.paths[0].completedDay, DayKey(date: Self.now))
            try store.setPathStatus(id: path.id, status: .active, on: Self.now)
            try store.recordPathEntry(milestoneID: milestone.id, value: 5, on: Self.now)
            XCTAssertEqual(store.state.pathProgress(path), 0.5)
            try store.setPathStatus(id: path.id, status: .archived)
            XCTAssertEqual(store.state.pathEntries.count, 1)
            XCTAssertThrowsError(try store.recordPathEntry(milestoneID: milestone.id, value: 7, on: Self.now))
        }
    }
    func testPathRejectsInvalidLinksUnitsAndDestructiveMilestoneEdits() async throws {
        try await MainActor.run {
            let store = try LifeStore(repository: MemoryStateRepository())
            let habit = Habit(title: "Read", createdAt: Self.now); try store.saveHabit(habit)
            XCTAssertThrowsError(try store.savePath(LifePath(title: "Bad", milestones: [PathMilestone(title: "Minutes", goalType: .duration, target: 10, habitID: habit.id)])))
            let milestone = PathMilestone(title: "Read", habitID: habit.id)
            var path = LifePath(title: "Read", startDay: DayKey(date: Self.now), milestones: [milestone])
            try store.savePath(path)
            try store.record(habitID: habit.id, value: 1, on: Self.now)
            try store.setPathStatus(id: path.id, status: .completed, on: Self.now)
            try store.record(habitID: habit.id, value: 0, on: Self.now)
            XCTAssertEqual(store.state.paths[0].status, .active)
            XCTAssertNil(store.state.paths[0].completedDay)
            path.milestones = [PathMilestone(title: "Replacement")]
            XCTAssertThrowsError(try store.savePath(path))
        }
    }
    func testSchemaTwoMigratesRoutineHistoryAndWidgetPreferences() async throws {
        try await MainActor.run {
            // Construct the exact schema-two shape, with a real partial routine session.
            let routine = Routine(title: "Morning", steps: [RoutineStep(title: "Read"), RoutineStep(title: "Walk")])
            var session = RoutineSession(routine: routine, day: DayKey(date: Self.now), timeZoneID: "UTC")
            session.completedStepIDs = [routine.steps[0].id]
            let state = LifeState(routines: [routine], routineSessions: [session])
            var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
            legacy.removeValue(forKey: "paths"); legacy.removeValue(forKey: "pathEntries")
            legacy.removeValue(forKey: "adaptivePlans")
            legacy["widgets"] = [["kind": "routines", "isVisible": true], ["kind": "habits", "isVisible": false], ["kind": "mode", "isVisible": true], ["kind": "progress", "isVisible": false]]
            let data = try JSONSerialization.data(withJSONObject: ["schemaVersion": 2, "state": legacy])
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appendingPathComponent("life.json"); try data.write(to: url)
            let repo = JSONStateRepository(url: url)
            let loaded = try repo.load()
            XCTAssertEqual(loaded.routines, [routine]); XCTAssertEqual(loaded.routineSessions, [session])
            XCTAssertEqual(loaded.widgets.map(\.kind), [.routines, .habits, .mode, .progress, .paths, .adaptive])
            XCTAssertEqual(loaded.widgets.map(\.isVisible), [true, false, true, false, false, false])
            XCTAssertEqual(try Data(contentsOf: url), data)
            try repo.save(loaded)
            XCTAssertEqual(loaded, try JSONStateRepository(url: url).load())
        }
    }
    func testFutureContributionsCannotBackdatePathCompletion() async throws {
        try await MainActor.run {
            let store = try LifeStore(repository: MemoryStateRepository())
            let milestone = PathMilestone(title: "Finish")
            let path = LifePath(title: "Learn", startDay: DayKey(date: Self.now), milestones: [milestone])
            try store.savePath(path)
            try store.recordPathEntry(milestoneID: milestone.id, value: 1, on: Self.now.addingTimeInterval(86400))
            XCTAssertThrowsError(try store.setPathStatus(id: path.id, status: .completed, on: Self.now))
            XCTAssertEqual(store.state.paths[0].status, .active)
            try store.setPathStatus(id: path.id, status: .completed, on: Self.now.addingTimeInterval(86400))
            XCTAssertEqual(store.state.paths[0].status, .completed)
            let habit = Habit(title: "Read", createdAt: Self.now)
            try store.saveHabit(habit)
            let linked = LifePath(title: "Read once", startDay: DayKey(date: Self.now), milestones: [PathMilestone(title: "One", habitID: habit.id)])
            try store.savePath(linked)
            try store.record(habitID: habit.id, value: 1, on: Self.now)
            try store.setPathStatus(id: linked.id, status: .completed, on: Self.now)
            try store.record(habitID: habit.id, value: 1, on: Self.now.addingTimeInterval(86400))
            try store.record(habitID: habit.id, value: 0, on: Self.now)
            XCTAssertEqual(store.state.paths[1].status, .active, "Future work must not conceal a corrected completion date")
        }
    }

    func testArchivedPathKeepsCompletionDateAfterRestartAndCorrectionsKeepItArchived() async throws {
        try await MainActor.run {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            let url = folder.appendingPathComponent("life.json")
            let store = try LifeStore(repository: JSONStateRepository(url: url))
            let habit = Habit(title: "Learn", goalType: .duration, target: 10, createdAt: Self.now)
            try store.saveHabit(habit)
            let milestone = PathMilestone(title: "Practice", goalType: .duration, target: 10, habitID: habit.id)
            let path = LifePath(title: "Learn", startDay: DayKey(date: Self.now), milestones: [milestone])
            try store.savePath(path)
            try store.record(habitID: habit.id, value: 10, on: Self.now)
            try store.setPathStatus(id: path.id, status: .completed, on: Self.now)
            try store.setPathStatus(id: path.id, status: .archived)

            let restored = try LifeStore(repository: JSONStateRepository(url: url))
            XCTAssertEqual(restored.state.paths[0].status, .archived)
            XCTAssertEqual(restored.state.paths[0].completedDay, DayKey(date: Self.now))
            XCTAssertEqual(restored.state.pathProgress(restored.state.paths[0]), 1)
            // Correcting the work invalidates its old completion, but preserves the archive choice.
            try restored.record(habitID: habit.id, value: 5, on: Self.now)
            XCTAssertEqual(restored.state.paths[0].status, .archived)
            XCTAssertNil(restored.state.paths[0].completedDay)
            XCTAssertEqual(restored.state.pathProgress(restored.state.paths[0]), 0.5)
            let corrected = try LifeStore(repository: JSONStateRepository(url: url))
            XCTAssertEqual(corrected.state, restored.state)
        }
    }

}

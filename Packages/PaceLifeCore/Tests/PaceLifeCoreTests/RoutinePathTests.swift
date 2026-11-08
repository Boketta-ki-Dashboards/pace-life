import Foundation
import XCTest
@testable import PaceLifeCore

final class RoutinePathTests: XCTestCase {
    func testRoutineCompletionCountsOnceAndCorrectionsReopenPathAfterRestart() async throws {
        try await MainActor.run {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            let url = folder.appendingPathComponent("life.json")
            let store = try LifeStore(repository: JSONStateRepository(url: url))
            let day = DayKey(rawValue: "2026-11-04"), date = day.civilDate!
            var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            let first = RoutineStep(title: "Prepare", minutes: 5), second = RoutineStep(title: "Practice", minutes: 10)
            var routine = Routine(title: "Learning", steps: [first, second], createdAt: date)
            try store.saveRoutine(routine)
            let milestone = PathMilestone(title: "One full session", goalType: .count, target: 1, routineID: routine.id)
            let path = LifePath(title: "Build a learning routine", startDay: day, milestones: [milestone]); try store.savePath(path)
            try store.startRoutine(id: routine.id, on: date, calendar: calendar)
            let session = store.state.routineSessions[0]
            try store.setRoutineStep(sessionID: session.id, stepID: first.id, completed: true)
            XCTAssertEqual(store.state.milestoneValue(milestone, in: path), 0, "Partial completion is not a full session")
            try store.setRoutineStep(sessionID: session.id, stepID: second.id, completed: true)
            try store.setRoutineStep(sessionID: session.id, stepID: second.id, completed: true)
            XCTAssertEqual(store.state.milestoneValue(milestone, in: path), 1)
            try store.setPathStatus(id: path.id, status: .completed, on: date, calendar: calendar)
            routine.steps = [RoutineStep(title: "New template", minutes: 100)]
            try store.saveRoutine(routine); try store.archiveRoutine(id: routine.id)
            let restored = try LifeStore(repository: JSONStateRepository(url: url))
            XCTAssertEqual(restored.state.milestoneValue(milestone, in: path), 1)
            XCTAssertEqual(restored.state.routineSessions[0].steps, [first, second])
            try restored.setRoutineStep(sessionID: session.id, stepID: second.id, completed: false)
            XCTAssertEqual(restored.state.milestoneValue(milestone, in: path), 0)
            XCTAssertEqual(restored.state.paths[0].status, .active)
            XCTAssertNil(restored.state.paths[0].completedDay)
        }
    }
    func testRoutineLinkRejectsInventedMinutesManualEntriesAndSourceChanges() async throws {
        try await MainActor.run {
            let store = try LifeStore(repository: MemoryStateRepository())
            let routine = Routine(title: "Practice", steps: [RoutineStep(title: "Read", minutes: 30)])
            try store.saveRoutine(routine)
            let duration = PathMilestone(title: "Minutes", goalType: .duration, target: 30, routineID: routine.id)
            XCTAssertThrowsError(try store.savePath(LifePath(title: "Invalid minutes", milestones: [duration])))
            let milestone = PathMilestone(title: "Complete", routineID: routine.id)
            var path = LifePath(title: "Complete routine", milestones: [milestone]); try store.savePath(path)
            XCTAssertThrowsError(try store.recordPathEntry(milestoneID: milestone.id, value: 1))
            path.milestones = [PathMilestone(id: milestone.id, title: milestone.title)]
            XCTAssertThrowsError(try store.savePath(path))
            let habit = Habit(title: "Read"); try store.saveHabit(habit)
            XCTAssertThrowsError(try store.savePath(LifePath(title: "Ambiguous", milestones: [PathMilestone(title: "Both", habitID: habit.id, routineID: routine.id)])))
        }
    }
    func testSchemaSevenWithoutRoutineLinksKeepsHistoryAndWritesCurrentSchema() async throws {
        try await MainActor.run {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appendingPathComponent("life.json")
            let original = LifeState(paths: [LifePath(title: "Legacy", milestones: [PathMilestone(title: "Manual")])], circles: [LocalCircle(title: "Local")])
            let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(original))
            let data = try JSONSerialization.data(withJSONObject: ["schemaVersion": 7, "state": json]); try data.write(to: url)
            let repo = JSONStateRepository(url: url)
            XCTAssertEqual(try repo.load(), original); XCTAssertEqual(try Data(contentsOf: url), data)
            try repo.save(original)
            let envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
            XCTAssertEqual(envelope["schemaVersion"] as? Int, 9)
            XCTAssertEqual(try JSONStateRepository(url: url).load(), original)
        }
    }
}

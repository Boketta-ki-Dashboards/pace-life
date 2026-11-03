import Foundation
import XCTest
@testable import PaceLifeCore

final class RoutineTests: XCTestCase {
    private static let monday = ISO8601DateFormatter().date(from: "2026-11-02T08:00:00Z")!
    private static var calendar: Calendar {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "Europe/Berlin")!; return c
    }
    func testModeRoutinePartialProgressSurvivesRestartTemplateEditAndModeDeletion() async throws {
        try await MainActor.run {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: directory) }
            let repo = JSONStateRepository(url: directory.appendingPathComponent("life.json"))
            let store = try LifeStore(repository: repo)
            let mode = LifeMode(title: "Work")
            try store.saveMode(mode)
            var routine = Routine(title: "Morning", modeID: mode.id, weekdays: [2], steps: (1...4).map { RoutineStep(title: "Step \($0)", minutes: 5) }, createdAt: Self.monday)
            try store.saveRoutine(routine)
            XCTAssertTrue(store.dueRoutines(on: Self.monday, calendar: Self.calendar).isEmpty)
            try store.activateMode(id: mode.id, at: Self.monday)
            try store.startRoutine(id: routine.id, on: Self.monday, calendar: Self.calendar)
            let session = try XCTUnwrap(store.state.routineSessions.first)
            for step in session.steps.prefix(2) { try store.setRoutineStep(sessionID: session.id, stepID: step.id, completed: true) }
            try store.setRoutinePaused(sessionID: session.id, paused: true)
            XCTAssertThrowsError(try store.setRoutineStep(sessionID: session.id, stepID: session.steps[2].id, completed: true))
            routine.title = "Changed"; routine.steps = [RoutineStep(title: "New")]
            try store.saveRoutine(routine)
            let restored = try LifeStore(repository: JSONStateRepository(url: repo.url))
            XCTAssertEqual(restored.state.routineSessions[0].progress, 0.5)
            XCTAssertFalse(restored.state.routineSessions[0].isComplete)
            XCTAssertTrue(restored.state.routineSessions[0].isPaused)
            try restored.startRoutine(id: routine.id, on: Self.monday, calendar: Self.calendar)
            XCTAssertEqual(restored.state.routineSessions.count, 1)
            XCTAssertFalse(restored.state.routineSessions[0].isPaused)
            try restored.deleteMode(id: mode.id, at: Self.monday.addingTimeInterval(60))
            XCTAssertNil(restored.state.routines[0].modeID)
            XCTAssertEqual(restored.state.routineSessions[0].modeIDSnapshot, mode.id)
            XCTAssertEqual(restored.state.routineSessions[0].titleSnapshot, "Morning")
            XCTAssertEqual(restored.state.routineSessions[0].steps, session.steps)
            for step in session.steps.suffix(2) { try restored.setRoutineStep(sessionID: session.id, stepID: step.id, completed: true) }
            XCTAssertTrue(restored.state.routineSessions[0].isComplete)
            try restored.setRoutineStep(sessionID: session.id, stepID: session.steps[0].id, completed: false)
            XCTAssertEqual(restored.state.routineSessions[0].progress, 0.75)
            try restored.archiveRoutine(id: routine.id)
            XCTAssertTrue(restored.dueRoutines(on: Self.monday, calendar: Self.calendar).isEmpty)
            XCTAssertEqual(restored.state.routineSessions.count, 1)
        }
    }
    func testRoutineValidationScheduleAndDuplicateSteps() async throws {
        try await MainActor.run {
            let store = try LifeStore(repository: MemoryStateRepository())
            let step = RoutineStep(title: "One")
            var routine = Routine(title: "Morning", weekdays: [2], steps: [step], createdAt: Self.monday)
            try store.saveRoutine(routine)
            XCTAssertThrowsError(try store.startRoutine(id: routine.id, on: Self.monday.addingTimeInterval(86400), calendar: Self.calendar))
            routine.steps = [step, step]; XCTAssertThrowsError(try store.saveRoutine(routine))
            routine.steps = []; XCTAssertThrowsError(try store.saveRoutine(routine))
            routine.steps = [step]; routine.modeID = UUID(); XCTAssertThrowsError(try store.saveRoutine(routine))
            routine.modeID = nil; routine.plannedMinute = 1440; XCTAssertThrowsError(try store.saveRoutine(routine))
            XCTAssertEqual(store.state.routines.count, 1)
        }
    }
    func testFailedRoutineWriteRollsBackSession() async throws {
        try await MainActor.run {
            let routine = Routine(title: "Morning", steps: [RoutineStep(title: "One")], createdAt: Self.monday)
            let store = try LifeStore(repository: RoutineWriteFailure(state: LifeState(routines: [routine])))
            XCTAssertThrowsError(try store.startRoutine(id: routine.id, on: Self.monday, calendar: Self.calendar))
            XCTAssertTrue(store.state.routineSessions.isEmpty)
        }
    }
}
@MainActor private struct RoutineWriteFailure: StateRepository {
    let state: LifeState
    func load() throws -> LifeState { state }
    func save(_ state: LifeState) throws { throw CocoaError(.fileWriteOutOfSpace) }
}

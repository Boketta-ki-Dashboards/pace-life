import Foundation
import XCTest
@testable import PaceLifeCore

final class AdaptiveTests: XCTestCase {
    private static let now = ISO8601DateFormatter().date(from: "2026-11-03T12:00:00Z")!
    func testPlanningRespectsBudgetsAndNeverAssumesUnknownDurations() throws {
        let habits = [60.0, 25, 15].map { Habit(title: "Minutes", goalType: .duration, target: $0) }
        let routine = Routine(title: "Morning", steps: [RoutineStep(title: "Stretch", minutes: 10), RoutineStep(title: "Reflect")])
        let binary = Habit(title: "Call")
        let state = LifeState(habits: habits + [binary], routines: [routine])
        for budget in [0, 5, 10, 30, 100, 1440] {
            let plan = try AdaptiveEngine.propose(state: state, habits: habits + [binary], routines: [routine], day: DayKey(date: Self.now), availableMinutes: budget, energy: 3, load: 3)
            XCTAssertLessThanOrEqual(plan.suggestedMinutes, Double(max(10, budget)))
            XCTAssertEqual(plan.unknownDurationCount, 2)
            XCTAssertTrue(plan.entries.allSatisfy { $0.decision == .pending && $0.acceptedTarget == nil })
            XCTAssertEqual(plan, try AdaptiveEngine.propose(state: state, habits: habits + [binary], routines: [routine], day: plan.day, availableMinutes: budget, energy: 3, load: 3))
        }
        let protected = try AdaptiveEngine.propose(state: state, habits: habits, routines: [routine], day: DayKey(date: Self.now), availableMinutes: 30, energy: 1, load: 5, protectedIDs: [habits[0].id])
        XCTAssertEqual(protected.entries[0].suggestedTarget, 60)
        XCTAssertEqual(protected.suggestedMinutes, 70)
        XCTAssertTrue(protected.exceedsBudget)
    }
    func testAcceptedGoalActualWorkAndPathContributionStaySeparateAfterRestart() async throws {
        try await MainActor.run {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            let url = folder.appendingPathComponent("life.json")
            let store = try LifeStore(repository: JSONStateRepository(url: url))
            var learn = Habit(title: "Learn", goalType: .duration, target: 60, createdAt: Self.now)
            let move = Habit(title: "Move", goalType: .duration, target: 40, createdAt: Self.now)
            try store.saveHabit(learn); try store.saveHabit(move)
            let mode = LifeMode(title: "Work", habitIDs: [learn.id, move.id])
            try store.saveMode(mode); try store.activateMode(id: mode.id, at: Self.now)
            let milestone = PathMilestone(title: "100 hours", goalType: .duration, target: 6000, habitID: learn.id)
            let path = LifePath(title: "Russian B2", startDay: DayKey(date: Self.now), milestones: [milestone])
            try store.savePath(path)
            try store.createAdaptivePlan(availableMinutes: 30, energy: 3, load: 3, on: Self.now)
            let plan = try XCTUnwrap(store.state.adaptivePlans.first)
            XCTAssertLessThanOrEqual(plan.suggestedMinutes, 30)
            XCTAssertGreaterThan(plan.entries[0].suggestedTarget, plan.entries[1].suggestedTarget)
            try store.decideAdaptive(day: plan.day, habitID: learn.id, decision: .accepted, target: 15, now: Self.now)
            try store.decideAdaptive(day: plan.day, habitID: move.id, decision: .declined, now: Self.now)
            learn.target = 5; try store.saveHabit(learn)
            try store.record(habitID: learn.id, value: 15, on: Self.now)
            let completion = try XCTUnwrap(store.state.completions.first)
            XCTAssertEqual(completion.targetSnapshot, 60)
            XCTAssertEqual(completion.progress, 0.25)
            XCTAssertFalse(completion.isComplete)
            XCTAssertEqual(store.state.milestoneValue(milestone, in: path), 15)
            let restored = try LifeStore(repository: JSONStateRepository(url: url))
            XCTAssertEqual(restored.state, store.state)
            XCTAssertEqual(restored.state.adaptivePlans[0].entries[0].acceptedTarget, 15)
            XCTAssertEqual(restored.state.adaptivePlans[0].effectiveMinutes, 55)
            XCTAssertTrue(restored.state.adaptivePlans[0].exceedsBudget)
            try restored.createAdaptivePlan(availableMinutes: 100, energy: 5, load: 1, on: Self.now)
            XCTAssertEqual(restored.state.adaptivePlans.count, 1)
            XCTAssertEqual(restored.state.adaptivePlans[0].availableMinutes, 30)
            try restored.decideAdaptive(day: plan.day, habitID: learn.id, decision: .reverted, now: Self.now)
            XCTAssertNil(restored.state.adaptivePlans[0].entries[0].acceptedTarget)
            XCTAssertEqual(restored.state.completions[0], completion)
            XCTAssertEqual(restored.state.milestoneValue(milestone, in: path), 15)
        }
    }
    func testAdaptiveRejectsPastDaysInvalidTargetsAndProtectedReductions() async throws {
        try await MainActor.run {
            let habit = Habit(title: "Learn", goalType: .duration, target: 60, createdAt: Self.now)
            let store = try LifeStore(repository: MemoryStateRepository(state: LifeState(habits: [habit])))
            try store.createAdaptivePlan(availableMinutes: 15, energy: 3, load: 3, protectedIDs: [habit.id], on: Self.now)
            let day = DayKey(date: Self.now)
            for target in [-1.0, 15, 100, .nan] {
                XCTAssertThrowsError(try store.decideAdaptive(day: day, habitID: habit.id, decision: .accepted, target: target, now: Self.now))
            }
            XCTAssertThrowsError(try store.decideAdaptive(day: day, habitID: habit.id, decision: .declined, now: Self.now.addingTimeInterval(86400)))
            XCTAssertEqual(store.state.adaptivePlans[0].entries[0].decision, .pending)
        }
    }
    func testSchemaThreeMigrationPreservesPathsAndRejectsMissingAdaptiveArray() async throws {
        try await MainActor.run {
            let milestone = PathMilestone(title: "Read")
            let path = LifePath(title: "Learn", milestones: [milestone])
            let state = LifeState(paths: [path])
            var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
            legacy.removeValue(forKey: "adaptivePlans")
            legacy.removeValue(forKey: "dayPlans")
            legacy["widgets"] = ["progress", "mode", "habits", "routines", "paths"].map { ["kind": $0, "isVisible": true] }
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appendingPathComponent("life.json")
            let data = try JSONSerialization.data(withJSONObject: ["schemaVersion": 3, "state": legacy]); try data.write(to: url)
            let repo = JSONStateRepository(url: url)
            let loaded = try repo.load()
            XCTAssertEqual(loaded.paths, [path]); XCTAssertTrue(loaded.adaptivePlans.isEmpty)
            XCTAssertEqual(loaded.widgets.first(where: { $0.kind == .adaptive }), HomeWidgetPreference(kind: .adaptive, isVisible: false))
            XCTAssertEqual(loaded.widgets.map(\.kind), [.mode, .habits, .routines, .paths, .adaptive].reduce(into: [HomeWidgetKind.overview, .progress, .streak, .week]) { $0.append($1) } + [.calendar, .circles, .experiments, .chapters])
            XCTAssertEqual(try Data(contentsOf: url), data)
            try repo.save(loaded); XCTAssertEqual(loaded, try JSONStateRepository(url: url).load())
            let corrupt = try JSONSerialization.data(withJSONObject: ["schemaVersion": 4, "state": legacy]); try corrupt.write(to: url)
            XCTAssertThrowsError(try JSONStateRepository(url: url).load())
            XCTAssertEqual(try Data(contentsOf: url), corrupt)
        }
    }
    func testZeroTargetIsDeferralAndFailedDecisionDoesNotMutateState() async throws {
        try await MainActor.run {
            let habit = Habit(title: "Learn", goalType: .duration, target: 60, createdAt: Self.now)
            let repository = AdaptiveWriteFailure(state: LifeState(habits: [habit]))
            let store = try LifeStore(repository: repository)
            try store.createAdaptivePlan(availableMinutes: 0, energy: 3, load: 3, on: Self.now)
            let day = DayKey(date: Self.now)
            repository.failWrites = true
            let before = store.state
            XCTAssertThrowsError(try store.decideAdaptive(day: day, habitID: habit.id, decision: .accepted, now: Self.now))
            XCTAssertEqual(store.state, before)
            repository.failWrites = false
            try store.decideAdaptive(day: day, habitID: habit.id, decision: .accepted, now: Self.now)
            XCTAssertEqual(store.state.adaptivePlans[0].entries[0].acceptedTarget, 0)
            try store.record(habitID: habit.id, value: 0, on: Self.now)
            XCTAssertFalse(store.state.completions[0].isComplete)
            XCTAssertEqual(store.state.completions[0].targetSnapshot, 60)
        }
    }

}

@MainActor private final class AdaptiveWriteFailure: StateRepository {
    var state: LifeState
    var failWrites = false
    init(state: LifeState) { self.state = state }
    func load() throws -> LifeState { state }
    func save(_ state: LifeState) throws {
        if failWrites { throw CocoaError(.fileWriteOutOfSpace) }
        self.state = state
    }
}

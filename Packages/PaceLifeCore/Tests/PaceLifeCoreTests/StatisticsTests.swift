import XCTest
@testable import PaceLifeCore

final class StatisticsTests: XCTestCase {
    func testDailyMetricsUseOnlyStoredResults() {
        let study = Habit(title: "Study", goalType: .duration, target: 60)
        let read = Habit(title: "Read")
        let routine = Routine(title: "Morning", steps: [RoutineStep(title: "A"), RoutineStep(title: "B")])
        var complete = RoutineSession(routine: routine, day: DayKey(rawValue: "2026-11-03"), timeZoneID: "UTC")
        complete.completedStepIDs = Set(routine.steps.map(\.id))
        var partial = RoutineSession(routine: routine, day: DayKey(rawValue: "2026-11-04"), timeZoneID: "UTC")
        partial.completedStepIDs = [routine.steps[0].id]
        func record(_ habit: Habit, _ day: String, _ value: Double) -> HabitCompletion {
            HabitCompletion(habitID: habit.id, day: DayKey(rawValue: day), timeZoneID: "UTC", actualValue: value,
                            targetSnapshot: habit.target, goalTypeSnapshot: habit.goalType)
        }
        let state = LifeState(habits: [study, read],
                              completions: [record(study, "2026-11-03", 30), record(read, "2026-11-03", 1),
                                            record(study, "2026-11-04", 75), record(read, "2026-11-05", 0)],
                              routines: [routine], routineSessions: [complete, partial])
        let nov3 = DayKey(rawValue: "2026-11-03"), nov4 = DayKey(rawValue: "2026-11-04"), nov5 = DayKey(rawValue: "2026-11-05")
        // A partial duration (30 of 60) is not a completed habit, but its minutes count as measured work.
        XCTAssertEqual(state.value(of: .completedHabits, on: nov3), 1)
        XCTAssertEqual(state.value(of: .minutes, on: nov3), 30)
        XCTAssertEqual(state.value(of: .completedRoutines, on: nov3), 1)
        XCTAssertEqual(state.value(of: .completedRoutines, on: nov4), 0, "Partial routine sessions do not count")
        XCTAssertEqual(state.value(of: .completedHabits, on: nov5), 0, "A reset binary result is not completed")
        XCTAssertEqual(state.total(of: .minutes, from: nov3, through: nov5), 105)
        XCTAssertEqual(state.bestDay(of: .minutes, from: nov3, through: nov5), MetricBest(start: nov4, end: nov4, value: 75))
        XCTAssertNil(state.bestDay(of: .completedRoutines, from: nov4, through: nov5))
        let weeks = [DayKey(rawValue: "2026-10-27"), DayKey(rawValue: "2026-11-03")]
        XCTAssertEqual(state.bestWeek(of: .completedHabits, weekStarts: weeks)?.start, DayKey(rawValue: "2026-11-03"))
        XCTAssertEqual(state.bestWeek(of: .minutes, weekStarts: weeks)?.value, 105)
    }
}

final class PathTimelineAndReplanTests: XCTestCase {
    func testPathTimelineFollowsCountedContributions() {
        let study = Habit(title: "Study", goalType: .duration, target: 60)
        let path = LifePath(title: "Learn", startDay: DayKey(rawValue: "2026-11-01"),
                            milestones: [PathMilestone(title: "Hours", goalType: .duration, target: 120, habitID: study.id), PathMilestone(title: "Exam")])
        let state = LifeState(habits: [study],
                              completions: [HabitCompletion(habitID: study.id, day: DayKey(rawValue: "2026-10-31"), timeZoneID: "UTC", actualValue: 60, targetSnapshot: 60, goalTypeSnapshot: .duration),
                                            HabitCompletion(habitID: study.id, day: DayKey(rawValue: "2026-11-02"), timeZoneID: "UTC", actualValue: 60, targetSnapshot: 60, goalTypeSnapshot: .duration)],
                              paths: [path],
                              pathEntries: [PathEntry(milestoneID: path.milestones[1].id, day: DayKey(rawValue: "2026-11-04"), value: 1)])
        let points = state.pathProgressTimeline(path, through: DayKey(rawValue: "2026-11-05"))
        XCTAssertEqual(points.map(\.day.rawValue), ["2026-11-01", "2026-11-02", "2026-11-04", "2026-11-05"], "Work before the path start is not counted")
        XCTAssertEqual(points.map(\.progress), [0, 0.25, 0.75, 0.75])
    }

    func testReplanKeepsDecisionsAndRefreshesPendingSuggestions() async throws {
        try await MainActor.run {
            let store = try LifeStore(repository: MemoryStateRepository())
            let study = Habit(title: "Study", goalType: .duration, target: 60), read = Habit(title: "Read", goalType: .duration, target: 40)
            try store.saveHabit(study); try store.saveHabit(read)
            try store.createAdaptivePlan(availableMinutes: 30, energy: 3, load: 3)
            let day = DayKey(date: Date())
            try store.decideAdaptive(day: day, habitID: study.id, decision: .accepted, target: 20)
            let before = try XCTUnwrap(store.state.adaptivePlans.first?.entries.first { $0.habitID == read.id })
            try store.replanAdaptive(availableMinutes: 120, energy: 3, load: 3)
            let plan = try XCTUnwrap(store.state.adaptivePlans.first)
            XCTAssertEqual(store.state.adaptivePlans.count, 1)
            XCTAssertEqual(plan.availableMinutes, 120)
            let kept = try XCTUnwrap(plan.entries.first { $0.habitID == study.id })
            XCTAssertEqual(kept.decision, .accepted); XCTAssertEqual(kept.acceptedTarget, 20); XCTAssertEqual(kept.originalTarget, 60)
            let refreshed = try XCTUnwrap(plan.entries.first { $0.habitID == read.id })
            XCTAssertEqual(refreshed.decision, .pending)
            XCTAssertGreaterThan(refreshed.suggestedTarget, before.suggestedTarget)
            XCTAssertLessThanOrEqual(refreshed.suggestedTarget, 40)
        }
    }
}

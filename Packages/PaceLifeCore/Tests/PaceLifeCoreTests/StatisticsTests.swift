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

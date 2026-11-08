#if DEBUG
import Foundation
import PaceLifeCore

/// Explicitly synthetic dashboard data for simulator screenshots and UI tests.
/// Only used with `--uitesting-seed-dashboard`, only inside the separate UI-test
/// store, and only when that store does not exist yet. Never part of Release builds.
@MainActor
enum UITestSeed {
    static func writeDashboard(to url: URL, now: Date = Date(), calendar: Calendar = .current) throws {
        guard !FileManager.default.fileExists(atPath: url.path) else { return }
        func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: now) ?? now }
        func key(_ offset: Int) -> DayKey { DayKey(date: day(offset), calendar: calendar) }
        let created = calendar.startOfDay(for: day(-30))
        let read = Habit(title: "Lesen", createdAt: created)
        let study = Habit(title: "Russisch lernen", goalType: .duration, target: 30, createdAt: created)
        let walk = Habit(title: "Spaziergang", createdAt: created)
        let habits = [read, study, walk]
        let mode = LifeMode(title: "Arbeitstag", habitIDs: Set(habits.map(\.id)))
        let routine = Routine(title: "Morgenroutine", modeID: mode.id, plannedMinute: 7 * 60,
                              steps: [RoutineStep(title: "Wasser trinken", minutes: 2), RoutineStep(title: "Dehnen", minutes: 10),
                                      RoutineStep(title: "Tag planen", minutes: 5)], createdAt: created)
        var completions: [HabitCompletion] = []
        var plans: [DayPlanSnapshot] = []
        // Nine past days: mostly reached, one partial day and one day without any entry.
        for offset in -9 ... -1 {
            plans.append(DayPlanSnapshot(day: key(offset), habitIDs: habits.map(\.id), routineIDs: [routine.id], modeID: mode.id, modeTitle: mode.title))
            if offset == -6 { continue }
            let minutes: Double = offset == -4 ? 15 : Double(30 + (offset + 9) * 5)
            completions.append(HabitCompletion(habitID: study.id, day: key(offset), timeZoneID: calendar.timeZone.identifier,
                                               actualValue: minutes, targetSnapshot: 30, goalTypeSnapshot: .duration))
            completions.append(HabitCompletion(habitID: read.id, day: key(offset), timeZoneID: calendar.timeZone.identifier,
                                               actualValue: 1, targetSnapshot: 1, goalTypeSnapshot: .binary))
            completions.append(HabitCompletion(habitID: walk.id, day: key(offset), timeZoneID: calendar.timeZone.identifier,
                                               actualValue: 1, targetSnapshot: 1, goalTypeSnapshot: .binary))
        }
        completions.append(HabitCompletion(habitID: read.id, day: key(0), timeZoneID: calendar.timeZone.identifier,
                                           actualValue: 1, targetSnapshot: 1, goalTypeSnapshot: .binary))
        completions.append(HabitCompletion(habitID: study.id, day: key(0), timeZoneID: calendar.timeZone.identifier,
                                           actualValue: 20, targetSnapshot: 30, goalTypeSnapshot: .duration))
        var session = RoutineSession(routine: routine, day: key(0), timeZoneID: calendar.timeZone.identifier)
        session.completedStepIDs = [routine.steps[0].id]
        let path = LifePath(title: "Russisch B2", category: "Lernen", startDay: key(-9),
                            milestones: [PathMilestone(title: "Grammatik wiederholen"),
                                         PathMilestone(title: "100 Lernstunden", goalType: .duration, target: 6000, habitID: study.id),
                                         PathMilestone(title: "B2-Test", goalType: .binary)])
        let entries = [PathEntry(milestoneID: path.milestones[0].id, day: key(-3), value: 1)]
        let state = LifeState(habits: habits, modes: [mode], completions: completions,
                              activations: [ModeActivation(modeID: mode.id, titleSnapshot: mode.title, start: created)],
                              activeModeID: mode.id, settings: AppSettings(displayName: "Alex"),
                              routines: [routine], routineSessions: [session], paths: [path], pathEntries: entries,
                              dayPlans: plans)
        try JSONStateRepository(url: url).save(state)
    }
}
#endif

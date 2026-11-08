import Foundation

public enum CalendarScope: String, CaseIterable, Sendable { case week, month }
public struct DayOverview: Sendable {
    public let day: DayKey
    /// Nil means the historical plan was never captured; it does not mean zero scheduled work.
    public let plannedHabits: [Habit]?
    public let plannedRoutines: [Routine]?
    public let completions: [HabitCompletion]
    public let routineSessions: [RoutineSession]
    public let adaptivePlan: DailyAdaptivePlan?
    public let isForecast: Bool
}
public enum PlanningCalendar {
    public static func days(containing date: Date, scope: CalendarScope, calendar: Calendar = .current) -> [Date] {
        var civil = Calendar(identifier: .gregorian)
        civil.timeZone = calendar.timeZone; civil.firstWeekday = calendar.firstWeekday
        civil.minimumDaysInFirstWeek = calendar.minimumDaysInFirstWeek
        guard let interval = civil.dateInterval(of: scope == .week ? .weekOfYear : .month, for: date) else { return [] }
        var days: [Date] = [], day = interval.start
        while day < interval.end {
            days.append(day)
            guard let next = civil.date(byAdding: .day, value: 1, to: day), next > day else { break }
            day = next
        }
        return days
    }
}
extension LifeStore {
    public func overview(on date: Date, today: Date = Date(), calendar: Calendar = .current) -> DayOverview {
        let day = DayKey(date: date, calendar: calendar), current = DayKey(date: today, calendar: calendar)
        // Past days show their frozen schema-9 plan when one was captured; otherwise unknown.
        let plan = state.plan(on: date, today: today, calendar: calendar)
        let habits = plan.map { plan in plan.habitIDs.compactMap { id in state.habits.first { $0.id == id } } }
        let routines = plan.map { plan in plan.routineIDs.compactMap { id in state.routines.first { $0.id == id } } }
        return DayOverview(day: day,
                           plannedHabits: habits,
                           plannedRoutines: routines,
                           completions: state.completions.filter { $0.day == day },
                           routineSessions: state.routineSessions.filter { $0.day == day },
                           adaptivePlan: state.adaptivePlans.first { $0.day == day }, isForecast: day > current)
    }
}

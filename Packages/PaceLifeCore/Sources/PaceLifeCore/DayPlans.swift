import Foundation

/// The frozen plan of one civil day (schema 9).
///
/// Snapshots are written inside every successful transaction. Days between the
/// newest snapshot and today are filled from the *pre-mutation* state: no change
/// could have happened in between, because every change is a transaction that
/// captures its own day. Today's snapshot follows the latest state; earlier
/// snapshots are never rewritten. Days before the first snapshot stay unknown
/// and are never reconstructed or treated as missed.
public struct DayPlanSnapshot: Identifiable, Codable, Equatable, Sendable {
    public var id: DayKey { day }
    public let day: DayKey
    public let habitIDs: [UUID]
    public let routineIDs: [UUID]
    public let modeID: UUID?
    /// Kept so a later deleted or renamed mode still explains the historical plan.
    public let modeTitle: String?
    public init(day: DayKey, habitIDs: [UUID], routineIDs: [UUID], modeID: UUID? = nil, modeTitle: String? = nil) {
        self.day = day
        self.habitIDs = habitIDs.sorted { $0.uuidString < $1.uuidString }
        self.routineIDs = routineIDs.sorted { $0.uuidString < $1.uuidString }
        self.modeID = modeID; self.modeTitle = modeTitle
    }
}

/// Honest result of one day. A nil plan means "unknown", never "missed".
public struct DaySummary: Equatable, Sendable {
    public let day: DayKey
    public let plannedHabitIDs: [UUID]?
    /// Every habit with a completed stored result on this day.
    public let completedHabitIDs: [UUID]
    /// Average progress of the planned habits; nil when the plan is unknown or empty.
    public let progress: Double?
    public let isForecast: Bool
    public var isRestDay: Bool { plannedHabitIDs?.isEmpty == true }
    public var plannedCompletedCount: Int {
        guard let planned = plannedHabitIDs else { return 0 }
        return Set(planned).intersection(completedHabitIDs).count
    }
    public var goalReached: Bool {
        guard !isForecast, let planned = plannedHabitIDs, !planned.isEmpty else { return false }
        return Set(planned).isSubset(of: Set(completedHabitIDs))
    }
}

/// Consecutive days on which every planned habit was completed. Rest days are
/// neutral, an unfinished today does not break the streak, unknown days do.
public struct LifeStreak: Equatable, Sendable {
    public let current: Int
    public let todayCompleted: Bool
    public let longest: Int
    public let longestStart: DayKey?
    public let longestEnd: DayKey?
}

extension LifeState {
    /// Habits scheduled on this date by the current definitions and active mode.
    public func dueHabits(on date: Date, calendar: Calendar = .current) -> [Habit] {
        let mode = modes.first { $0.id == activeModeID }
        return habits.filter { $0.isDue(on: date, calendar: calendar) && (mode == nil || mode!.habitIDs.contains($0.id)) }
    }

    public func dueRoutines(on date: Date, calendar: Calendar = .current) -> [Routine] {
        routines.filter { $0.isDue(on: date, calendar: calendar) && ($0.modeID == nil || $0.modeID == activeModeID) }
            .sorted { ($0.plannedMinute ?? 1440, $0.title, $0.id.uuidString) < ($1.plannedMinute ?? 1440, $1.title, $1.id.uuidString) }
    }

    func makeDayPlan(on date: Date, calendar: Calendar) -> DayPlanSnapshot {
        let mode = modes.first { $0.id == activeModeID }
        return DayPlanSnapshot(day: DayKey(date: date, calendar: calendar),
                               habitIDs: dueHabits(on: date, calendar: calendar).map(\.id),
                               routineIDs: dueRoutines(on: date, calendar: calendar).map(\.id),
                               modeID: mode?.id, modeTitle: mode?.title)
    }

    static let maximumGapDays = 366

    /// Called on the candidate of every transaction. `previous` is the state before the change.
    mutating func captureDayPlans(previous: LifeState, now: Date, calendar: Calendar) {
        let today = DayKey(date: now, calendar: calendar)
        if let last = dayPlans.map(\.day).max() {
            // A clock moved backwards must never rewrite stored history.
            guard last <= today else { return }
            var cursor = last.adding(days: 1)
            var filled = 0
            while let day = cursor, day < today, filled < Self.maximumGapDays,
                  let date = day.localDate(calendar: calendar) {
                dayPlans.append(previous.makeDayPlan(on: date, calendar: calendar))
                filled += 1
                cursor = day.adding(days: 1)
            }
        }
        let snapshot = makeDayPlan(on: now, calendar: calendar)
        if let index = dayPlans.firstIndex(where: { $0.day == today }) {
            if dayPlans[index] != snapshot { dayPlans[index] = snapshot }
        } else {
            dayPlans.append(snapshot)
        }
        dayPlans.sort { $0.day < $1.day }
    }

    /// The stored plan, or the plan the next transaction would freeze for an
    /// uncaptured day after the newest snapshot (including today and forecasts).
    public func plan(on date: Date, today: Date = Date(), calendar: Calendar = .current) -> DayPlanSnapshot? {
        let day = DayKey(date: date, calendar: calendar)
        if let stored = dayPlans.first(where: { $0.day == day }) { return stored }
        let current = DayKey(date: today, calendar: calendar)
        if day >= current { return makeDayPlan(on: date, calendar: calendar) }
        guard let last = dayPlans.map(\.day).max(), day > last,
              let limit = last.adding(days: Self.maximumGapDays), day <= limit else { return nil }
        return makeDayPlan(on: date, calendar: calendar)
    }

    public func summary(on date: Date, today: Date = Date(), calendar: Calendar = .current) -> DaySummary {
        let day = DayKey(date: date, calendar: calendar)
        let planned = plan(on: date, today: today, calendar: calendar)?.habitIDs
        let records = completions.filter { $0.day == day }
        let progress: Double? = planned.flatMap { ids in
            guard !ids.isEmpty else { return nil }
            return ids.reduce(0) { total, id in total + (records.first { $0.habitID == id }?.progress ?? 0) } / Double(ids.count)
        }
        return DaySummary(day: day, plannedHabitIDs: planned,
                          completedHabitIDs: records.filter(\.isComplete).map(\.habitID),
                          progress: progress, isForecast: day > DayKey(date: today, calendar: calendar))
    }

    public func lifeStreak(today: Date = Date(), calendar: Calendar = .current) -> LifeStreak {
        let current = DayKey(date: today, calendar: calendar)
        func summary(_ day: DayKey) -> DaySummary? {
            day.localDate(calendar: calendar).map { self.summary(on: $0, today: today, calendar: calendar) }
        }
        // Current streak, walking backwards from today.
        var count = 0, todayDone = false, cursor: DayKey? = current
        if let first = summary(current), first.goalReached { count = 1; todayDone = true }
        cursor = current.adding(days: -1)
        var steps = 0
        while let day = cursor, steps < 3660, let result = summary(day), let planned = result.plannedHabitIDs {
            if !planned.isEmpty {
                guard result.goalReached else { break }
                count += 1
            }
            cursor = day.adding(days: -1); steps += 1
        }
        // Longest streak across all known days.
        var longest = 0, longestStart: DayKey?, longestEnd: DayKey?
        if let first = dayPlans.map(\.day).min() {
            var run = 0, runStart: DayKey?, day: DayKey? = first, guardSteps = 0
            while let value = day, value <= current, guardSteps < 3660 {
                guardSteps += 1
                defer { day = value.adding(days: 1) }
                guard let result = summary(value), let planned = result.plannedHabitIDs else { run = 0; runStart = nil; continue }
                if planned.isEmpty { continue }
                if result.goalReached {
                    if run == 0 { runStart = value }
                    run += 1
                    if run > longest { longest = run; longestStart = runStart; longestEnd = value }
                } else if value != current {
                    run = 0; runStart = nil
                }
            }
        }
        // The current run is part of the known days above, so `longest >= count`.
        return LifeStreak(current: count, todayCompleted: todayDone, longest: longest,
                          longestStart: longestStart, longestEnd: longestEnd)
    }

    func validateDayPlans() throws {
        let habitIDs = Set(habits.map(\.id)), routineIDs = Set(routines.map(\.id))
        guard Set(dayPlans.map(\.day)).count == dayPlans.count else { throw LifeError.corruptStore }
        for plan in dayPlans {
            guard plan.day.isValid,
                  Set(plan.habitIDs).count == plan.habitIDs.count, Set(plan.habitIDs).isSubset(of: habitIDs),
                  Set(plan.routineIDs).count == plan.routineIDs.count, Set(plan.routineIDs).isSubset(of: routineIDs),
                  (plan.modeID == nil) == (plan.modeTitle == nil),
                  plan.modeTitle.map({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? true else {
                throw LifeError.corruptStore
            }
        }
    }
}

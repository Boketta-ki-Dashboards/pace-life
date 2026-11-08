import Foundation

/// Measured daily values. They never depend on a plan: only stored results count.
public enum DailyMetric: String, CaseIterable, Sendable {
    /// Completed habit results of the day.
    case completedHabits
    /// Actual minutes recorded on duration habits.
    case minutes
    /// Fully completed routine sessions.
    case completedRoutines
}

public struct MetricBest: Equatable, Sendable {
    public let start: DayKey
    public let end: DayKey
    public let value: Double
}

extension LifeState {
    public func value(of metric: DailyMetric, on day: DayKey) -> Double {
        switch metric {
        case .completedHabits:
            return Double(completions.filter { $0.day == day && $0.isComplete }.count)
        case .minutes:
            return completions.filter { $0.day == day && $0.goalTypeSnapshot == .duration }.reduce(0) { $0 + $1.actualValue }
        case .completedRoutines:
            return Double(routineSessions.filter { $0.day == day && $0.isComplete }.count)
        }
    }

    public func total(of metric: DailyMetric, from start: DayKey, through end: DayKey) -> Double {
        var sum = 0.0, cursor: DayKey? = start, guardSteps = 0
        while let day = cursor, day <= end, guardSteps < 400 {
            sum += value(of: metric, on: day)
            cursor = day.adding(days: 1); guardSteps += 1
        }
        return sum
    }

    /// Best single day with a positive value within the range (earliest wins ties).
    public func bestDay(of metric: DailyMetric, from start: DayKey, through end: DayKey) -> MetricBest? {
        var best: MetricBest?, cursor: DayKey? = start, guardSteps = 0
        while let day = cursor, day <= end, guardSteps < 400 {
            let current = value(of: metric, on: day)
            if current > 0, current > (best?.value ?? 0) { best = MetricBest(start: day, end: day, value: current) }
            cursor = day.adding(days: 1); guardSteps += 1
        }
        return best
    }

    /// Best seven-day calendar week (starting on `weekStart` days) within the range.
    public func bestWeek(of metric: DailyMetric, weekStarts: [DayKey]) -> MetricBest? {
        var best: MetricBest?
        for start in weekStarts {
            guard let end = start.adding(days: 6) else { continue }
            let sum = total(of: metric, from: start, through: end)
            if sum > 0, sum > (best?.value ?? 0) { best = MetricBest(start: start, end: end, value: sum) }
        }
        return best
    }
}

public struct PathProgressPoint: Equatable, Sendable {
    public let day: DayKey
    public let progress: Double
}

extension LifeState {
    /// Overall path progress after each day with a counted contribution, starting at the path start.
    public func pathProgressTimeline(_ path: LifePath, through today: DayKey) -> [PathProgressPoint] {
        var days: Set<DayKey> = [path.startDay]
        for milestone in path.milestones {
            days.formUnion(pathEntries.filter { $0.milestoneID == milestone.id }.map(\.day))
            if let habitID = milestone.habitID {
                days.formUnion(completions.filter { $0.habitID == habitID && $0.goalTypeSnapshot == milestone.goalType && $0.day >= path.startDay }.map(\.day))
            }
            if let routineID = milestone.routineID {
                days.formUnion(routineSessions.filter { $0.routineID == routineID && $0.isComplete && $0.day >= path.startDay }.map(\.day))
            }
        }
        if path.startDay <= today { days.insert(today) }
        return days.filter { $0 <= today }.sorted().map { PathProgressPoint(day: $0, progress: pathProgress(path, through: $0)) }
    }
}

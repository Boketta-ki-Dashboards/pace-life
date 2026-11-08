import Foundation

public enum GoalType: String, Codable, CaseIterable, Sendable { case binary, count, duration }

public struct Habit: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var goalType: GoalType
    public var target: Double
    /// Calendar weekday numbers: Sunday = 1, Saturday = 7.
    public var weekdays: Set<Int>
    public let createdAt: Date
    public var isArchived: Bool

    public init(id: UUID = UUID(), title: String, goalType: GoalType = .binary,
                target: Double = 1, weekdays: Set<Int> = Set(1...7),
                createdAt: Date = Date(), isArchived: Bool = false) {
        self.id = id; self.title = title; self.goalType = goalType; self.target = target
        self.weekdays = weekdays; self.createdAt = createdAt; self.isArchived = isArchived
    }

    public func isDue(on date: Date, calendar: Calendar = .current) -> Bool {
        !isArchived && calendar.startOfDay(for: date) >= calendar.startOfDay(for: createdAt)
            && weekdays.contains(calendar.component(.weekday, from: date))
    }
}

/// A Gregorian local civil day. Persisting the day rather than a UTC midnight avoids DST drift.
/// Changing time zones does not relabel existing history; identical civil dates deduplicate.
public struct DayKey: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(date: Date, calendar: Calendar = .current) {
        var civil = Calendar(identifier: .gregorian)
        civil.timeZone = calendar.timeZone
        let components = civil.dateComponents([.year, .month, .day], from: date)
        rawValue = String(format: "%04d-%02d-%02d", components.year!, components.month!, components.day!)
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct HabitCompletion: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let habitID: UUID
    public let day: DayKey
    public let timeZoneID: String
    public var actualValue: Double
    public let targetSnapshot: Double
    public let goalTypeSnapshot: GoalType
    public var isComplete: Bool { actualValue >= targetSnapshot }
    public var progress: Double { min(1, max(0, actualValue / targetSnapshot)) }

    public init(id: UUID = UUID(), habitID: UUID, day: DayKey, timeZoneID: String,
                actualValue: Double, targetSnapshot: Double, goalTypeSnapshot: GoalType) {
        self.id = id; self.habitID = habitID; self.day = day; self.timeZoneID = timeZoneID
        self.actualValue = actualValue; self.targetSnapshot = targetSnapshot
        self.goalTypeSnapshot = goalTypeSnapshot
    }
}

public struct LifeMode: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    /// Selected habits form this mode's daily template. Empty means no selected habits.
    public var habitIDs: Set<UUID>
    /// Weekdays (Sunday = 1) on which this mode activates automatically (schema 10).
    /// Nil or empty means manual only. With overlapping schedules the first mode in the list wins.
    public var scheduledWeekdays: Set<Int>?
    /// Up to three ordered daily priorities among the mode's habits (schema 10).
    public var priorityHabitIDs: [UUID]?
    public init(id: UUID = UUID(), title: String, habitIDs: Set<UUID> = [], scheduledWeekdays: Set<Int>? = nil, priorityHabitIDs: [UUID]? = nil) {
        self.id = id; self.title = title; self.habitIDs = habitIDs; self.scheduledWeekdays = scheduledWeekdays
        self.priorityHabitIDs = priorityHabitIDs
    }
}

public struct ModeActivation: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let modeID: UUID
    public let titleSnapshot: String
    public let start: Date
    public var end: Date?
    /// True when the weekly mode schedule started this activation (schema 10); nil = manual or legacy.
    public let isAutomatic: Bool?
    public init(id: UUID = UUID(), modeID: UUID, titleSnapshot: String, start: Date, end: Date? = nil, isAutomatic: Bool? = nil) {
        self.id = id; self.modeID = modeID; self.titleSnapshot = titleSnapshot; self.start = start; self.end = end
        self.isAutomatic = isAutomatic
    }
}

public enum HomeWidgetKind: String, Codable, CaseIterable, Sendable {
    case progress, mode, habits, routines, paths, adaptive
    /// Introduced with schema 9 (Pace dashboard).
    case overview, streak, week, calendar, circles, experiments, chapters
}
/// A user-selected density. Nil keeps the widget's default (regular).
public enum HomeWidgetSize: String, Codable, CaseIterable, Sendable { case compact, regular, large }
public struct HomeWidgetPreference: Identifiable, Codable, Equatable, Sendable {
    public var id: HomeWidgetKind { kind }
    public let kind: HomeWidgetKind
    public var isVisible: Bool
    /// Optional so that documents written before sizes existed keep their meaning.
    public var size: HomeWidgetSize?
    public init(kind: HomeWidgetKind, isVisible: Bool = true, size: HomeWidgetSize? = nil) {
        self.kind = kind; self.isVisible = isVisible; self.size = size
    }
    public var resolvedSize: HomeWidgetSize { size ?? .regular }

    /// First-launch layout of the Pace dashboard. Module widgets start hidden and can be added.
    public static var defaultLayout: [HomeWidgetPreference] {
        let visible: [HomeWidgetKind] = [.overview, .progress, .streak, .habits, .routines, .week, .mode, .paths, .adaptive, .calendar]
        let hidden: [HomeWidgetKind] = [.circles, .experiments, .chapters]
        return visible.map { HomeWidgetPreference(kind: $0) } + hidden.map { HomeWidgetPreference(kind: $0, isVisible: false) }
    }

    /// Schema 9 adds dashboard widgets. Every existing preference keeps its order,
    /// visibility and size; only missing kinds are inserted at defined positions.
    public static func upgradingToSchemaNine(_ widgets: [HomeWidgetPreference]) -> [HomeWidgetPreference] {
        var result = widgets
        func has(_ kind: HomeWidgetKind) -> Bool { result.contains { $0.kind == kind } }
        func index(after kind: HomeWidgetKind) -> Int { result.firstIndex { $0.kind == kind }.map { $0 + 1 } ?? result.count }
        if !has(.overview) { result.insert(HomeWidgetPreference(kind: .overview), at: result.firstIndex { $0.kind == .progress } ?? 0) }
        if !has(.streak) { result.insert(HomeWidgetPreference(kind: .streak), at: index(after: .progress)) }
        if !has(.week) { result.insert(HomeWidgetPreference(kind: .week), at: index(after: .streak)) }
        if !has(.calendar) { result.append(HomeWidgetPreference(kind: .calendar)) }
        for kind in [HomeWidgetKind.circles, .experiments, .chapters] where !has(kind) {
            result.append(HomeWidgetPreference(kind: kind, isVisible: false))
        }
        return result
    }
}

public enum AppTheme: String, Codable, CaseIterable, Sendable { case system, light, dark }
public enum AppLanguage: String, Codable, CaseIterable, Sendable { case de, en, ru }
public struct AppSettings: Codable, Equatable, Sendable {
    public var theme: AppTheme
    public var language: AppLanguage
    /// Optional local first name for the home greeting. Never shared or synced.
    public var displayName: String?
    public init(theme: AppTheme = .system, language: AppLanguage = .de, displayName: String? = nil) {
        self.theme = theme; self.language = language; self.displayName = displayName
    }
}

public struct LifeState: Codable, Equatable, Sendable {
    /// Frozen daily plans (schema 9). Days before the first snapshot stay unknown.
    public var dayPlans: [DayPlanSnapshot]
    /// Local notification preferences (schema 10).
    public var reminders: [Reminder]
    /// Day of the last manual mode choice. It overrides the weekly schedule for that day only.
    public var modeOverrideDay: DayKey?
    public var circles: [LocalCircle]
    public var circleChallenges: [CircleChallenge]
    public var circleContributions: [CircleContribution]
    public var experiments: [LifeExperiment]
    public var experimentCheckIns: [ExperimentCheckIn]
    public var chapters: [LifeChapter]
    public var adaptivePlans: [DailyAdaptivePlan]
    public var paths: [LifePath]
    public var pathEntries: [PathEntry]
    public var routines: [Routine]
    public var routineSessions: [RoutineSession]
    public var habits: [Habit]
    public var modes: [LifeMode]
    public var completions: [HabitCompletion]
    public var activations: [ModeActivation]
    public var activeModeID: UUID?
    /// Array position is the user's explicit widget order.
    public var widgets: [HomeWidgetPreference]
    public var settings: AppSettings
    public init(habits: [Habit] = [], modes: [LifeMode] = [], completions: [HabitCompletion] = [],
                activations: [ModeActivation] = [], activeModeID: UUID? = nil,
                widgets: [HomeWidgetPreference] = HomeWidgetPreference.defaultLayout,
                settings: AppSettings = AppSettings(), routines: [Routine] = [], routineSessions: [RoutineSession] = [], paths: [LifePath] = [], pathEntries: [PathEntry] = [], adaptivePlans: [DailyAdaptivePlan] = [], chapters: [LifeChapter] = [], experiments: [LifeExperiment] = [], experimentCheckIns: [ExperimentCheckIn] = [], circles: [LocalCircle] = [], circleChallenges: [CircleChallenge] = [], circleContributions: [CircleContribution] = [], dayPlans: [DayPlanSnapshot] = [], reminders: [Reminder] = [], modeOverrideDay: DayKey? = nil) {
        self.dayPlans = dayPlans; self.reminders = reminders; self.modeOverrideDay = modeOverrideDay
        self.circles = circles; self.circleChallenges = circleChallenges; self.circleContributions = circleContributions
        self.experiments = experiments; self.experimentCheckIns = experimentCheckIns
        self.chapters = chapters
        self.adaptivePlans = adaptivePlans
        self.paths = paths; self.pathEntries = pathEntries
        self.routines = routines; self.routineSessions = routineSessions
        self.habits = habits; self.modes = modes; self.completions = completions
        self.activations = activations; self.activeModeID = activeModeID; self.widgets = widgets; self.settings = settings
    }
}

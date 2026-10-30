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
    public init(id: UUID = UUID(), title: String, habitIDs: Set<UUID> = []) {
        self.id = id; self.title = title; self.habitIDs = habitIDs
    }
}

public struct ModeActivation: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let modeID: UUID
    public let titleSnapshot: String
    public let start: Date
    public var end: Date?
    public init(id: UUID = UUID(), modeID: UUID, titleSnapshot: String, start: Date, end: Date? = nil) {
        self.id = id; self.modeID = modeID; self.titleSnapshot = titleSnapshot; self.start = start; self.end = end
    }
}

public enum HomeWidgetKind: String, Codable, CaseIterable, Sendable { case progress, mode, habits }
public struct HomeWidgetPreference: Identifiable, Codable, Equatable, Sendable {
    public var id: HomeWidgetKind { kind }
    public let kind: HomeWidgetKind
    public var isVisible: Bool
    public init(kind: HomeWidgetKind, isVisible: Bool = true) { self.kind = kind; self.isVisible = isVisible }
}

public enum AppTheme: String, Codable, CaseIterable, Sendable { case system, light, dark }
public enum AppLanguage: String, Codable, CaseIterable, Sendable { case de, en, ru }
public struct AppSettings: Codable, Equatable, Sendable {
    public var theme: AppTheme
    public var language: AppLanguage
    public init(theme: AppTheme = .system, language: AppLanguage = .de) { self.theme = theme; self.language = language }
}

public struct LifeState: Codable, Equatable, Sendable {
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
                widgets: [HomeWidgetPreference] = HomeWidgetKind.allCases.map { HomeWidgetPreference(kind: $0) },
                settings: AppSettings = AppSettings()) {
        self.habits = habits; self.modes = modes; self.completions = completions
        self.activations = activations; self.activeModeID = activeModeID; self.widgets = widgets; self.settings = settings
    }
}

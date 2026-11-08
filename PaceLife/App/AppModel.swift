import Foundation
import Observation
import SwiftUI
import PaceLifeCore

/// Composition-facing observable state. Views invoke use cases here; only the core repository touches disk.
@MainActor @Observable
final class AppModel {
    private(set) var state = LifeState()
    private(set) var loaded = false
    var saveFailed = false
    var photoFailed = false
    @ObservationIgnored let photos: any ChapterPhotoRepository
    var today = Date()
    @ObservationIgnored private var store: LifeStore?
    @ObservationIgnored private let repository: any StateRepository

    init(repository: any StateRepository, photos: any ChapterPhotoRepository) {
        self.photos = photos
        self.repository = repository
        reload()
    }

    func reload() {
        do {
            let service = try LifeStore(repository: repository)
            store = service
            state = service.state
            loaded = true
            saveFailed = false
        } catch { loaded = false }
    }

    func refreshDay() { today = Date() }
    var locale: Locale { Locale(identifier: state.settings.language.rawValue) }
    var colorScheme: ColorScheme? {
        switch state.settings.theme { case .system: nil; case .light: .light; case .dark: .dark }
    }
    var dueHabits: [Habit] {
        _ = state // Register observation before consulting the use-case layer.
        return store?.dueHabits(on: today) ?? []
    }
    var activeHabits: [Habit] { state.habits.filter { !$0.isArchived } }
    var activeMode: LifeMode? { state.modes.first { $0.id == state.activeModeID } }
    var progress: Double {
        _ = state
        return store?.progress(on: today) ?? 0
    }
    var completedCount: Int { dueHabits.filter { completion($0)?.isComplete == true }.count }
    func completion(_ habit: Habit) -> HabitCompletion? {
        _ = state
        return store?.completion(habitID: habit.id, on: today)
    }
    func text(_ key: Copy) -> String { key.text(state.settings.language) }
    func number(_ value: Double) -> String { value.formatted(.number.locale(locale).precision(.fractionLength(0...2))) }
    func inputNumber(_ value: Double) -> String { value.formatted(.number.locale(locale).grouping(.never).precision(.fractionLength(0...8))) }
    /// Strict editable numbers: no grouping, exponent, suffix or partial parsing.
    func parseNumber(_ input: String) -> Double? {
        let formatter = NumberFormatter(); formatter.locale = locale
        let separator = formatter.decimalSeparator ?? "."
        guard separator == "." || !input.contains(".") else { return nil }
        let normalized = input.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: separator, with: ".")
        guard normalized.range(of: #"^[0-9]+(?:\.[0-9]+)?$"#, options: .regularExpression) != nil,
              let value = Double(normalized), value.isFinite else { return nil }
        return value
    }
    func weekday(_ day: Int) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        return calendar.weekdaySymbols[day - 1]
    }
    var weekdays: [Int] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        return (0..<7).map { ((calendar.firstWeekday - 1 + $0) % 7) + 1 }
    }
    func goalName(_ kind: GoalType) -> String {
        switch kind { case .binary: text(.binary); case .count: text(.count); case .duration: text(.duration) }
    }
    func widgetName(_ kind: HomeWidgetKind) -> String {
        switch kind {
        case .progress: text(.progress); case .mode: text(.activeMode); case .habits: text(.habits); case .routines: text(.routines)
        case .paths: "Life Paths"; case .adaptive: "Pace Adaptive"
        case .overview: dash(.overview); case .streak: text(.streak); case .week: dash(.yourWeek); case .calendar: dash(.calendarTitle)
        case .circles: dash(.yourCirclesWidget); case .experiments: "Life Experiments"; case .chapters: "Life Chapters"
        }
    }
    @discardableResult func perform(_ action: (LifeStore) throws -> Void) -> Bool {
        guard let store else { return false }
        do { try action(store); state = store.state; saveFailed = false; return true }
        catch { saveFailed = true; return false }
    }
    func saveHabit(_ habit: Habit) -> Bool { perform { try $0.saveHabit(habit) } }
    func archiveHabit(_ habit: Habit) -> Bool { perform { try $0.archiveHabit(id: habit.id) } }
    func saveMode(_ mode: LifeMode) -> Bool { perform { try $0.saveMode(mode) } }
    func deleteMode(_ mode: LifeMode) -> Bool { perform { try $0.deleteMode(id: mode.id) } }
    func activateMode(_ id: UUID?) { perform { try $0.activateMode(id: id) } }
    func record(_ habit: Habit, value: Double, on date: Date = Date()) -> Bool {
        today = date
        return perform { try $0.record(habitID: habit.id, value: value, on: date) }
    }
    func setWidgets(_ widgets: [HomeWidgetPreference]) -> Bool { perform { try $0.setWidgets(widgets) } }
    func setTheme(_ theme: AppTheme) {
        var settings = state.settings; settings.theme = theme
        perform { try $0.setSettings(settings) }
    }
    func setLanguage(_ language: AppLanguage) {
        var settings = state.settings; settings.language = language
        perform { try $0.setSettings(settings) }
    }
}


extension AppModel {
    var dueRoutines: [Routine] { _ = state; return store?.dueRoutines(on: today) ?? [] }
    func routineSession(_ id: UUID) -> RoutineSession? { _ = state; return store?.routineSession(routineID: id, on: today) }
    func saveRoutine(_ routine: Routine) -> Bool { perform { try $0.saveRoutine(routine) } }
    func archiveRoutine(_ id: UUID) { perform { try $0.archiveRoutine(id: id) } }
    func startRoutine(_ id: UUID) { perform { try $0.startRoutine(id: id, on: today) } }
    func pauseRoutine(_ id: UUID, paused: Bool) { perform { try $0.setRoutinePaused(sessionID: id, paused: paused) } }
    func setRoutineStep(_ session: RoutineSession, stepID: UUID, completed: Bool) {
        guard session.day == DayKey(date: today) else { return }
        perform { try $0.setRoutineStep(sessionID: session.id, stepID: stepID, completed: completed) }
    }
}


extension AppModel {
    func savePath(_ path: LifePath) -> Bool { perform { try $0.savePath(path) } }
    func setPathStatus(_ id: UUID, _ status: PathStatus) { perform { try $0.setPathStatus(id: id, status: status) } }
    func recordPathEntry(_ id: UUID, value: Double) -> Bool { perform { try $0.recordPathEntry(milestoneID: id, value: value) } }
}


extension AppModel {
    var adaptivePlan: DailyAdaptivePlan? { state.adaptivePlans.first { $0.day == DayKey(date: today) } }
    func adaptiveEntry(_ habit: Habit) -> AdaptiveEntry? { state.adaptiveEntry(habitID: habit.id, day: DayKey(date: today)) }
    func dayGoalType(_ habit: Habit) -> GoalType { completion(habit)?.goalTypeSnapshot ?? (adaptiveEntry(habit) == nil ? habit.goalType : .duration) }
    func dayTarget(_ habit: Habit) -> Double { completion(habit)?.targetSnapshot ?? adaptiveEntry(habit)?.originalTarget ?? habit.target }
    func proposeAdaptive(available: Int, energy: Int, load: Int, protectedIDs: Set<UUID>) {
        refreshDay()
        perform { try $0.createAdaptivePlan(availableMinutes: available, energy: energy, load: load, protectedIDs: protectedIDs, on: today) }
    }
    @discardableResult func decideAdaptive(_ day: DayKey, habitID: UUID, decision: AdaptiveDecision, target: Double? = nil) -> Bool {
        perform { try $0.decideAdaptive(day: day, habitID: habitID, decision: decision, target: target) }
    }
}


extension AppModel {
    func overview(on date: Date) -> DayOverview? { _ = state; return store?.overview(on: date, today: today) }
}


extension AppModel {
    func dayLabel(_ day: DayKey) -> String {
        let parser = DateFormatter()
        parser.calendar = Calendar(identifier: .gregorian)
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: day.rawValue) else { return day.rawValue }
        let display = DateFormatter()
        display.calendar = Calendar(identifier: .gregorian)
        display.locale = locale; display.timeZone = parser.timeZone; display.dateStyle = .medium
        return display.string(from: date)
    }
    func routineTime(_ routine: Routine) -> String? {
        guard let minute = routine.plannedMinute,
              let date = Calendar.current.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: today) else { return nil }
        return date.formatted(.dateTime.hour().minute().locale(locale))
    }
}


// MARK: - Pace dashboard, statistics and profile helpers
extension AppModel {
    /// Same calendar as the due-habit queries, so plans, summaries and records agree.
    var planCalendar: Calendar { Calendar.current }
    /// Display calendar for grids: Gregorian keys, user language, local time zone.
    var displayCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale; calendar.timeZone = .current
        return calendar
    }
    func summary(on date: Date) -> DaySummary {
        state.summary(on: date, today: today, calendar: planCalendar)
    }
    var todaySummary: DaySummary { summary(on: today) }
    var lifeStreak: LifeStreak { state.lifeStreak(today: today, calendar: planCalendar) }
    func days(containing date: Date, scope: CalendarScope) -> [Date] {
        PlanningCalendar.days(containing: date, scope: scope, calendar: displayCalendar)
    }
    func metricValue(_ metric: DailyMetric, on date: Date) -> Double {
        state.value(of: metric, on: DayKey(date: date, calendar: planCalendar))
    }
    func percent(_ value: Double) -> String {
        (value.isFinite ? value : 0).formatted(.percent.locale(locale).precision(.fractionLength(0)))
    }
    func signedNumber(_ value: Double) -> String { (value > 0 ? "+" : "") + number(value) }
    func weekdayShort(_ day: Int) -> String {
        let symbols = displayCalendar.shortStandaloneWeekdaySymbols
        return String(symbols[day - 1].prefix(2))
    }
    func greeting() -> String {
        if let name = state.settings.displayName { return dash(.greetingNamed, name) }
        return text(.today)
    }
    func setDisplayName(_ name: String) {
        let trimmed = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        var settings = state.settings
        settings.displayName = trimmed.isEmpty ? nil : trimmed
        guard settings != state.settings else { return }
        perform { try $0.setSettings(settings) }
    }

    func nextMilestone(in path: LifePath) -> PathMilestone? {
        path.milestones.first { state.milestoneValue($0, in: path) < $0.target }
    }
    func habitStreak(_ habit: Habit) -> Int {
        _ = state
        return store?.currentStreak(habitID: habit.id, on: today) ?? 0
    }
    func habitIcon(_ type: GoalType) -> String {
        switch type { case .binary: "checkmark.circle"; case .count: "number"; case .duration: "timer" }
    }
    func habitScheduleSummary(_ habit: Habit) -> String {
        let goal = habit.goalType == .binary ? goalName(.binary)
            : number(habit.target) + (habit.goalType == .duration ? " " + text(.minutes) : " · " + goalName(.count))
        let days = habit.weekdays.count == 7 ? text(.everyDay)
            : weekdays.filter { habit.weekdays.contains($0) }.map { weekdayShort($0) }.joined(separator: " ")
        return goal + " · " + days
    }
    func modeSummary(_ mode: LifeMode) -> String {
        let routines = state.routines.filter { $0.modeID == mode.id && !$0.isArchived }.count
        return number(Double(mode.habitIDs.count)) + " " + text(.habits) + " · " + number(Double(routines)) + " " + text(.routines)
    }
    /// Sum of actual minutes recorded today on duration habits.
    var todayMinutes: Double { metricValue(.minutes, on: today) }
    var completedRoutineCount: Int { dueRoutines.filter { routineSession($0.id)?.isComplete == true }.count }

    func experimentCheckedInToday(_ experiment: LifeExperiment) -> Bool {
        state.experimentCheckIns.contains { $0.experimentID == experiment.id && $0.day == DayKey(date: today) && !$0.values.isEmpty }
    }
    func experimentDaysLabel(_ days: Int) -> String {
        "/ " + number(Double(days)) + " " + experimentText(.days)
    }
    func circleMembersLine(_ circle: LocalCircle) -> String {
        number(Double(circle.members.count)) + " " + circleText(.members)
    }
    func adaptiveHistoryLine(_ entry: AdaptiveEntry, actual: Double) -> String {
        var parts = [adaptiveText(.actual) + ": " + number(actual), adaptiveText(.original) + ": " + number(entry.originalTarget)]
        if let target = entry.acceptedTarget { parts.append(adaptiveText(.adjusted) + ": " + number(target)) }
        return parts.joined(separator: " · ")
    }
    func widgetSizeName(_ size: HomeWidgetSize) -> String {
        switch size { case .compact: dash(.sizeCompact); case .regular: dash(.sizeRegular); case .large: dash(.sizeLarge) }
    }
    func widgetIcon(_ kind: HomeWidgetKind) -> String {
        switch kind {
        case .overview: "square.grid.2x2"
        case .progress: "chart.pie"
        case .streak: "flame"
        case .habits: "checklist"
        case .routines: "list.bullet.rectangle"
        case .week: "chart.bar"
        case .mode: "circle.hexagongrid"
        case .paths: "point.topleft.down.to.point.bottomright.curvepath"
        case .adaptive: "slider.horizontal.3"
        case .calendar: "calendar"
        case .circles: "person.2"
        case .experiments: "flask"
        case .chapters: "book.closed"
        }
    }
    /// Sizes a widget actually renders differently; the menu offers only these.
    func supportedSizes(_ kind: HomeWidgetKind) -> [HomeWidgetSize] {
        switch kind {
        case .progress, .week, .calendar: [.compact, .regular]
        case .habits, .paths, .routines: [.compact, .regular, .large]
        default: []
        }
    }
}

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
    var today = Date()
    @ObservationIgnored private var store: LifeStore?
    @ObservationIgnored private let repository: any StateRepository

    init(repository: any StateRepository) {
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
        switch kind { case .progress: text(.progress); case .mode: text(.activeMode); case .habits: text(.habits) }
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

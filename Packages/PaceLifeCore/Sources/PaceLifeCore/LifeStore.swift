import Foundation

/// Application use cases. Every mutation is committed in memory only after durable storage succeeds.
@MainActor public final class LifeStore {
    public private(set) var state: LifeState
    private let repository: any StateRepository
    private let now: () -> Date
    private let calendar: Calendar

    /// `now` and `calendar` only decide which civil day a transaction's plan snapshot belongs to.
    public init(repository: any StateRepository, now: @escaping () -> Date = { Date() }, calendar: Calendar = .current) throws {
        self.repository = repository
        self.now = now
        self.calendar = calendar
        let loaded = try repository.load()
        try loaded.validate()
        state = loaded
    }

    func transaction(_ change: (inout LifeState) throws -> Void) throws {
        var candidate = state
        try change(&candidate)
        // Correcting actual work or raising a milestone target can reopen a completed path.
        for index in candidate.paths.indices where candidate.paths[index].completedDay != nil {
            if candidate.pathProgress(candidate.paths[index], through: candidate.paths[index].completedDay) < 1 {
                // An invalidated historical completion must not unarchive a path.
                if candidate.paths[index].status == .completed { candidate.paths[index].status = .active }
                candidate.paths[index].completedDay = nil
            }
        }
        candidate.captureDayPlans(previous: state, now: now(), calendar: calendar)
        try candidate.validate()
        try repository.save(candidate)
        state = candidate
    }

    public func saveHabit(_ habit: Habit) throws {
        var clean = habit
        clean.title = habit.title.trimmingCharacters(in: .whitespacesAndNewlines)
        try clean.validate()
        try transaction { state in
            if let index = state.habits.firstIndex(where: { $0.id == clean.id }) { state.habits[index] = clean }
            else { state.habits.append(clean) }
        }
    }

    /// Archiving preserves completion history and mode references; due queries omit archived habits.
    public func archiveHabit(id: UUID) throws {
        try transaction { state in
            guard let index = state.habits.firstIndex(where: { $0.id == id }) else { throw LifeError.missingHabit }
            state.habits[index].isArchived = true
            // Archived habits no longer remind; their scheduled notifications disappear on the next sync.
            state.reminders.removeAll { $0.target == .habit(id) }
        }
    }

    public func saveMode(_ mode: LifeMode) throws {
        var clean = mode
        clean.title = mode.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.title.isEmpty else { throw LifeError.invalidTitle }
        guard clean.habitIDs.isSubset(of: Set(state.habits.map(\.id))) else { throw LifeError.missingHabit }
        try transaction { state in
            if let index = state.modes.firstIndex(where: { $0.id == clean.id }) { state.modes[index] = clean }
            else { state.modes.append(clean) }
        }
    }

    public func deleteMode(id: UUID, at date: Date = Date()) throws {
        try transaction { state in
            guard state.modes.contains(where: { $0.id == id }) else { throw LifeError.missingMode }
            if state.activeModeID == id {
                try Self.closeActivation(in: &state, at: date)
                state.activeModeID = nil
            }
            state.modes.removeAll { $0.id == id }
            for index in state.routines.indices where state.routines[index].modeID == id {
                state.routines[index].modeID = nil
            }
        }
    }

    public func activateMode(id: UUID?, at date: Date = Date()) throws {
        guard id != state.activeModeID else { return }
        let mode = state.modes.first { $0.id == id }
        guard id == nil || mode != nil else { throw LifeError.missingMode }
        try transaction { state in
            try Self.closeActivation(in: &state, at: date)
            state.activeModeID = id
            // A manual choice overrides the weekly schedule for the rest of this day.
            state.modeOverrideDay = DayKey(date: date, calendar: calendar)
            if let mode {
                state.activations.append(ModeActivation(modeID: mode.id, titleSnapshot: mode.title, start: date))
            }
        }
    }

    private static func closeActivation(in state: inout LifeState, at date: Date) throws {
        if let index = state.activations.lastIndex(where: { $0.end == nil }) {
            guard date >= state.activations[index].start else { throw LifeError.invalidActivationDate }
            state.activations[index].end = date
        }
    }

    public func record(habitID: UUID, value: Double, on date: Date = Date(), calendar: Calendar = .current) throws {
        guard let habit = state.habits.first(where: { $0.id == habitID }), !habit.isArchived else { throw LifeError.missingHabit }
        let day = DayKey(date: date, calendar: calendar)
        let existing = state.completions.first { $0.habitID == habitID && $0.day == day }
        let adaptive = state.adaptiveEntry(habitID: habitID, day: day)
        guard existing != nil || adaptive != nil || habit.isDue(on: date, calendar: calendar) else { throw LifeError.invalidSchedule }
        let type = existing?.goalTypeSnapshot ?? (adaptive == nil ? habit.goalType : .duration)
        guard value.isFinite, value >= 0,
              type != .binary || value == 0 || value == 1,
              type != .count || value.rounded() == value else { throw LifeError.invalidValue }
        try transaction { state in
            if let index = state.completions.firstIndex(where: { $0.habitID == habitID && $0.day == day }) {
                state.completions[index].actualValue = value
            } else {
                state.completions.append(HabitCompletion(habitID: habitID, day: day,
                    timeZoneID: calendar.timeZone.identifier, actualValue: value,
                    targetSnapshot: adaptive?.originalTarget ?? habit.target, goalTypeSnapshot: type))
            }
        }
    }

    public func setWidgets(_ widgets: [HomeWidgetPreference]) throws {
        try LifeState.validateWidgets(widgets)
        try transaction { $0.widgets = widgets }
    }
    public func setSettings(_ settings: AppSettings) throws { try transaction { $0.settings = settings } }

    public func dueHabits(on date: Date = Date(), calendar: Calendar = .current) -> [Habit] {
        state.dueHabits(on: date, calendar: calendar)
    }
    public func completion(habitID: UUID, on date: Date = Date(), calendar: Calendar = .current) -> HabitCompletion? {
        let day = DayKey(date: date, calendar: calendar)
        return state.completions.first { $0.habitID == habitID && $0.day == day }
    }
    /// Partial counts/durations remain partial; a reduced or edited goal cannot inflate a saved day's progress.
    public func progress(on date: Date = Date(), calendar: Calendar = .current) -> Double {
        let habits = dueHabits(on: date, calendar: calendar)
        guard !habits.isEmpty else { return 0 }
        return habits.reduce(0) { $0 + (completion(habitID: $1.id, on: date, calendar: calendar)?.progress ?? 0) } / Double(habits.count)
    }

    /// Consecutive completed scheduled days using the habit's current schedule. An unfinished today
    /// does not erase yesterday's streak. This is not a historical reconstruction of past schedules.
    public func currentStreak(habitID: UUID, on date: Date = Date(), calendar: Calendar = .current) -> Int {
        guard let habit = state.habits.first(where: { $0.id == habitID }) else { return 0 }
        var cursor = calendar.startOfDay(for: date)
        let earliest = calendar.startOfDay(for: habit.createdAt)
        var streak = 0
        var isToday = true
        while cursor >= earliest {
            if habit.weekdays.contains(calendar.component(.weekday, from: cursor)) {
                if completion(habitID: habitID, on: cursor, calendar: calendar)?.isComplete == true { streak += 1 }
                else if !isToday { break }
            }
            isToday = false
            guard let prior = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prior
        }
        return streak
    }
}

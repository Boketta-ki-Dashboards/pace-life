import Foundation

// MARK: - Recurring Life Modes (schema 10)
//
// Transparent rule, evaluated per civil day:
// 1. A manual mode choice made today wins for the rest of today.
// 2. Otherwise the first mode in the list scheduled for today's weekday is active.
// 3. Without a scheduled mode, an automatically started mode ends (all habits);
//    a mode chosen manually on an earlier day stays active.
// The rule is idempotent, so the mode never flips back and forth within a day.

extension LifeState {
    public func scheduledMode(on date: Date, calendar: Calendar = .current) -> LifeMode? {
        let weekday = calendar.component(.weekday, from: date)
        return modes.first { $0.scheduledWeekdays?.contains(weekday) == true }
    }

    /// Today's priorities of the active mode, in their chosen order.
    public var activePriorityHabitIDs: [UUID] {
        modes.first { $0.id == activeModeID }?.priorityHabitIDs ?? []
    }

    var activeModeIsAutomatic: Bool {
        activations.last(where: { $0.end == nil })?.isAutomatic == true
    }

    /// The mode a day would have without any transaction on that day.
    func effectiveModeID(on date: Date, calendar: Calendar) -> UUID? {
        if let scheduled = scheduledMode(on: date, calendar: calendar) { return scheduled.id }
        return activeModeIsAutomatic ? nil : activeModeID
    }
}

extension LifeStore {
    /// Applies the weekly schedule for `date`. Returns true when the active mode changed.
    @discardableResult
    public func applyModeSchedule(at date: Date = Date(), calendar: Calendar = .current) throws -> Bool {
        let today = DayKey(date: date, calendar: calendar)
        guard state.modeOverrideDay != today else { return false }
        let target = state.effectiveModeID(on: date, calendar: calendar)
        guard target != state.activeModeID else { return false }
        let mode = state.modes.first { $0.id == target }
        try transaction { state in
            if let index = state.activations.lastIndex(where: { $0.end == nil }) {
                guard date >= state.activations[index].start else { throw LifeError.invalidActivationDate }
                state.activations[index].end = date
            }
            state.activeModeID = target
            if let mode {
                state.activations.append(ModeActivation(modeID: mode.id, titleSnapshot: mode.title, start: date, isAutomatic: true))
            }
        }
        return true
    }
}

extension LifeMode {
    public static let maximumPriorities = 3
}

// MARK: - Local reminders (schema 10)

public enum ReminderTarget: Codable, Hashable, Sendable {
    case habit(UUID)
    case routine(UUID)
}

public struct Reminder: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let target: ReminderTarget
    /// Minutes after local midnight.
    public var minute: Int
    /// Calendar weekdays, Sunday = 1.
    public var weekdays: Set<Int>
    public var isEnabled: Bool
    public init(id: UUID = UUID(), target: ReminderTarget, minute: Int, weekdays: Set<Int> = Set(1...7), isEnabled: Bool = true) {
        self.id = id; self.target = target; self.minute = minute; self.weekdays = weekdays; self.isEnabled = isEnabled
    }
}

/// One weekly repeating notification request derived from a reminder.
public struct ScheduledReminder: Equatable, Sendable {
    public let identifier: String
    public let title: String
    public let weekday: Int
    public let hour: Int
    public let minute: Int
}

extension LifeState {
    /// iOS keeps at most 64 pending local notifications per app.
    public static let maximumScheduledNotifications = 64

    func reminderTitle(_ target: ReminderTarget) -> String? {
        switch target {
        case .habit(let id): habits.first { $0.id == id && !$0.isArchived }?.title
        case .routine(let id): routines.first { $0.id == id && !$0.isArchived }?.title
        }
    }

    /// Enabled reminders of active habits and routines, one request per weekday.
    public func scheduledReminders() -> [ScheduledReminder] {
        reminders.filter(\.isEnabled).flatMap { reminder -> [ScheduledReminder] in
            guard let title = reminderTitle(reminder.target) else { return [] }
            return reminder.weekdays.sorted().map {
                ScheduledReminder(identifier: "pace.reminder.\(reminder.id.uuidString).\($0)", title: title,
                                  weekday: $0, hour: reminder.minute / 60, minute: reminder.minute % 60)
            }
        }
    }

    func validateSchedules() throws {
        guard Set(reminders.map(\.id)).count == reminders.count else { throw LifeError.corruptStore }
        for reminder in reminders {
            guard (0..<1440).contains(reminder.minute), !reminder.weekdays.isEmpty, reminder.weekdays.isSubset(of: Set(1...7)) else {
                throw LifeError.invalidSchedule
            }
            switch reminder.target {
            case .habit(let id): guard habits.contains(where: { $0.id == id }) else { throw LifeError.missingHabit }
            case .routine(let id): guard routines.contains(where: { $0.id == id }) else { throw LifeError.missingRoutine }
            }
        }
        guard scheduledReminders().count <= Self.maximumScheduledNotifications else { throw LifeError.invalidSchedule }
        for mode in modes {
            if let days = mode.scheduledWeekdays { guard days.isSubset(of: Set(1...7)) else { throw LifeError.invalidSchedule } }
            if let priorities = mode.priorityHabitIDs {
                guard priorities.count <= LifeMode.maximumPriorities, Set(priorities).count == priorities.count,
                      Set(priorities).isSubset(of: mode.habitIDs) else { throw LifeError.invalidValue }
            }
        }
        if let day = modeOverrideDay { guard day.isValid else { throw LifeError.corruptStore } }
    }
}

extension LifeStore {
    public func saveReminder(_ reminder: Reminder) throws {
        let isNew = !state.reminders.contains { $0.id == reminder.id }
        if isNew {
            guard state.reminderTitle(reminder.target) != nil else { throw LifeError.invalidValue }
        } else {
            guard state.reminders.contains(where: { $0.id == reminder.id && $0.target == reminder.target }) else { throw LifeError.invalidValue }
        }
        try transaction { state in
            if let index = state.reminders.firstIndex(where: { $0.id == reminder.id }) { state.reminders[index] = reminder }
            else { state.reminders.append(reminder) }
        }
    }

    public func deleteReminder(id: UUID) throws {
        try transaction { state in
            guard state.reminders.contains(where: { $0.id == id }) else { throw LifeError.invalidValue }
            state.reminders.removeAll { $0.id == id }
        }
    }
}

// MARK: - Backup documents

extension JSONStateRepository {
    /// Decodes any supported schema exactly like `load()`, without touching disk.
    public static func decodeDocument(_ data: Data) throws -> LifeState {
        struct Header: Decodable { let schemaVersion: Int }
        let decoder = JSONDecoder()
        let version: Int
        do { version = try decoder.decode(Header.self, from: data).schemaVersion }
        catch { throw LifeError.corruptStore }
        guard (1...currentSchemaVersion).contains(version) else { throw LifeError.unsupportedSchema(version) }
        do {
            let state: LifeState
            switch version {
            case 1: state = try decoder.decode(SchemaOneEnvelope.self, from: data).state.migrated()
            case 2: state = try decoder.decode(SchemaTwoEnvelope.self, from: data).state.migrated()
            case 3: state = try decoder.decode(SchemaThreeEnvelope.self, from: data).state.migrated()
            case 4: state = try decoder.decode(SchemaFourEnvelope.self, from: data).state.migrated()
            case 5: state = try decoder.decode(SchemaFiveEnvelope.self, from: data).state.migrated()
            case 6: state = try decoder.decode(SchemaSixEnvelope.self, from: data).state.migrated()
            // Schema 8 only added an optional milestone field; its top-level shape equals schema 7.
            case 7, 8: state = try decoder.decode(SchemaSevenEnvelope.self, from: data).state.migrated()
            case 9: state = try decoder.decode(SchemaNineEnvelope.self, from: data).state.migrated()
            default: state = try decoder.decode(CurrentEnvelope.self, from: data).state
            }
            try state.validate()
            return state
        } catch { throw LifeError.corruptStore }
    }

    /// Human-readable export of a validated state in the current schema.
    public static func encodeDocument(_ state: LifeState, pretty: Bool = false) throws -> Data {
        try state.validate()
        let encoder = JSONEncoder()
        encoder.outputFormatting = pretty ? [.sortedKeys, .prettyPrinted] : [.sortedKeys]
        return try encoder.encode(CurrentEnvelope(schemaVersion: currentSchemaVersion, state: state))
    }
}

struct CurrentEnvelope: Codable {
    let schemaVersion: Int
    let state: LifeState
}

extension LifeStore {
    /// Replaces all data with a validated backup in one atomic write.
    public func restore(_ backup: LifeState) throws {
        try backup.validate()
        try transaction { $0 = backup }
    }
}

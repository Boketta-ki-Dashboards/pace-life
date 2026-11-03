import Foundation

public struct RoutineStep: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var minutes: Int?
    public init(id: UUID = UUID(), title: String, minutes: Int? = nil) {
        self.id = id; self.title = title; self.minutes = minutes
    }
}

public struct Routine: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var notes: String
    public var modeID: UUID?
    public var weekdays: Set<Int>
    /// Minutes after local midnight, without scheduling notifications.
    public var plannedMinute: Int?
    public var steps: [RoutineStep]
    public let createdAt: Date
    public var isArchived: Bool
    public init(id: UUID = UUID(), title: String, notes: String = "", modeID: UUID? = nil,
                weekdays: Set<Int> = Set(1...7), plannedMinute: Int? = nil,
                steps: [RoutineStep], createdAt: Date = Date(), isArchived: Bool = false) {
        self.id = id; self.title = title; self.notes = notes; self.modeID = modeID
        self.weekdays = weekdays; self.plannedMinute = plannedMinute; self.steps = steps
        self.createdAt = createdAt; self.isArchived = isArchived
    }
    public func isDue(on date: Date, calendar: Calendar = .current) -> Bool {
        !isArchived && calendar.startOfDay(for: date) >= calendar.startOfDay(for: createdAt)
            && weekdays.contains(calendar.component(.weekday, from: date))
    }
}

/// Immutable daily plan, separate from the editable template. No step is auto-completed.
public struct RoutineSession: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let routineID: UUID
    public let day: DayKey
    public let timeZoneID: String
    public let titleSnapshot: String
    public let modeIDSnapshot: UUID?
    public let steps: [RoutineStep]
    public var completedStepIDs: Set<UUID>
    public var isPaused: Bool
    public var isComplete: Bool { !steps.isEmpty && completedStepIDs.count == steps.count }
    public var progress: Double { steps.isEmpty ? 0 : Double(completedStepIDs.count) / Double(steps.count) }
    public init(id: UUID = UUID(), routine: Routine, day: DayKey, timeZoneID: String) {
        self.id = id; routineID = routine.id; self.day = day; self.timeZoneID = timeZoneID
        titleSnapshot = routine.title; modeIDSnapshot = routine.modeID; steps = routine.steps
        completedStepIDs = []; isPaused = false
    }
}

extension Routine {
    func validate() throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw LifeError.invalidTitle }
        guard !weekdays.isEmpty, weekdays.isSubset(of: Set(1...7)),
              createdAt.timeIntervalSinceReferenceDate.isFinite,
              plannedMinute.map({ (0..<1440).contains($0) }) ?? true else { throw LifeError.invalidSchedule }
        try Self.validateSteps(steps)
    }
    static func validateSteps(_ steps: [RoutineStep]) throws {
        guard !steps.isEmpty, Set(steps.map(\.id)).count == steps.count,
              steps.allSatisfy({ !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                  && ($0.minutes.map { (1...1440).contains($0) } ?? true) }) else { throw LifeError.invalidValue }
    }
}

extension LifeState {
    func validateRoutines() throws {
        guard Set(routines.map(\.id)).count == routines.count,
              Set(routineSessions.map(\.id)).count == routineSessions.count else { throw LifeError.corruptStore }
        for routine in routines {
            try routine.validate()
            guard routine.modeID == nil || modes.contains(where: { $0.id == routine.modeID }) else { throw LifeError.missingMode }
        }
        var keys: Set<String> = []
        for session in routineSessions {
            try Routine.validateSteps(session.steps)
            guard routines.contains(where: { $0.id == session.routineID }), session.day.isValid,
                  TimeZone(identifier: session.timeZoneID) != nil,
                  !session.titleSnapshot.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  session.completedStepIDs.isSubset(of: Set(session.steps.map(\.id))),
                  keys.insert(session.routineID.uuidString + session.day.rawValue).inserted else { throw LifeError.corruptStore }
        }
    }
}

extension LifeStore {
    public func saveRoutine(_ routine: Routine) throws {
        var clean = routine
        clean.title = clean.title.trimmingCharacters(in: .whitespacesAndNewlines)
        clean.steps = clean.steps.map { var step = $0; step.title = step.title.trimmingCharacters(in: .whitespacesAndNewlines); return step }
        try clean.validate()
        try transaction { state in
            if let index = state.routines.firstIndex(where: { $0.id == clean.id }) { state.routines[index] = clean }
            else { state.routines.append(clean) }
        }
    }
    public func archiveRoutine(id: UUID) throws {
        try transaction { state in
            guard let index = state.routines.firstIndex(where: { $0.id == id }) else { throw LifeError.missingRoutine }
            state.routines[index].isArchived = true
        }
    }
    public func dueRoutines(on date: Date = Date(), calendar: Calendar = .current) -> [Routine] {
        state.routines.filter { $0.isDue(on: date, calendar: calendar)
            && ($0.modeID == nil || $0.modeID == state.activeModeID) }
            .sorted { ($0.plannedMinute ?? 1440, $0.title, $0.id.uuidString) < ($1.plannedMinute ?? 1440, $1.title, $1.id.uuidString) }
    }
    public func routineSession(routineID: UUID, on date: Date = Date(), calendar: Calendar = .current) -> RoutineSession? {
        state.routineSessions.first { $0.routineID == routineID && $0.day == DayKey(date: date, calendar: calendar) }
    }
    /// Starting twice resumes the same session; edits never recreate its original step plan.
    public func startRoutine(id: UUID, on date: Date = Date(), calendar: Calendar = .current) throws {
        if let existing = routineSession(routineID: id, on: date, calendar: calendar) {
            try setRoutinePaused(sessionID: existing.id, paused: false); return
        }
        guard let routine = dueRoutines(on: date, calendar: calendar).first(where: { $0.id == id }) else { throw LifeError.missingRoutine }
        try transaction { $0.routineSessions.append(RoutineSession(routine: routine, day: DayKey(date: date, calendar: calendar), timeZoneID: calendar.timeZone.identifier)) }
    }
    public func setRoutinePaused(sessionID: UUID, paused: Bool) throws {
        try transaction { state in
            guard let index = state.routineSessions.firstIndex(where: { $0.id == sessionID }) else { throw LifeError.missingRoutine }
            state.routineSessions[index].isPaused = paused
        }
    }
    public func setRoutineStep(sessionID: UUID, stepID: UUID, completed: Bool) throws {
        try transaction { state in
            guard let index = state.routineSessions.firstIndex(where: { $0.id == sessionID }),
                  state.routineSessions[index].steps.contains(where: { $0.id == stepID }),
                  !state.routineSessions[index].isPaused else { throw LifeError.invalidValue }
            if completed { state.routineSessions[index].completedStepIDs.insert(stepID) }
            else { state.routineSessions[index].completedStepIDs.remove(stepID) }
        }
    }
}

import Foundation

public enum PathStatus: String, Codable, CaseIterable, Sendable { case active, paused, completed, archived }
public struct PathMilestone: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public let goalType: GoalType
    public var target: Double
    /// A linked milestone counts actual values with the same frozen unit from startDay onward.
    /// Manual and habit contributions are mutually exclusive to avoid counting work twice.
    public let habitID: UUID?
    public init(id: UUID = UUID(), title: String, goalType: GoalType = .binary, target: Double = 1, habitID: UUID? = nil) {
        self.id = id; self.title = title; self.goalType = goalType; self.target = target; self.habitID = habitID
    }
}
public struct LifePath: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var notes: String
    public var category: String
    public let startDay: DayKey
    public var targetDay: DayKey?
    public var status: PathStatus
    public var completedDay: DayKey?
    public var milestones: [PathMilestone]
    public init(id: UUID = UUID(), title: String, notes: String = "", category: String = "", startDay: DayKey = DayKey(date: Date()), targetDay: DayKey? = nil, milestones: [PathMilestone]) {
        self.id = id; self.title = title; self.notes = notes; self.category = category
        self.startDay = startDay; self.targetDay = targetDay; self.status = .active
        self.completedDay = nil; self.milestones = milestones
    }
}
public struct PathEntry: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let milestoneID: UUID
    public let day: DayKey
    public var value: Double
    public init(id: UUID = UUID(), milestoneID: UUID, day: DayKey, value: Double) {
        self.id = id; self.milestoneID = milestoneID; self.day = day; self.value = value
    }
}
extension LifeState {
    public func milestoneValue(_ milestone: PathMilestone, in path: LifePath, through day: DayKey? = nil) -> Double {
        if let habitID = milestone.habitID {
            return completions.filter { $0.habitID == habitID && $0.goalTypeSnapshot == milestone.goalType
                && $0.day >= path.startDay && (day == nil || $0.day <= day!) }.reduce(0) { $0 + $1.actualValue }
        }
        return pathEntries.filter { $0.milestoneID == milestone.id && (day == nil || $0.day <= day!) }.reduce(0) { $0 + $1.value }
    }
    public func pathProgress(_ path: LifePath, through day: DayKey? = nil) -> Double {
        guard !path.milestones.isEmpty else { return 0 }
        return path.milestones.reduce(0) { $0 + min(1, milestoneValue($1, in: path, through: day) / $1.target) } / Double(path.milestones.count)
    }
    func validatePaths() throws {
        let milestones = paths.flatMap(\.milestones)
        guard Set(paths.map(\.id)).count == paths.count, Set(milestones.map(\.id)).count == milestones.count,
              Set(pathEntries.map(\.id)).count == pathEntries.count else { throw LifeError.corruptStore }
        for path in paths {
            guard !path.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !path.milestones.isEmpty,
                  path.startDay.isValid, path.targetDay.map({ $0.isValid && $0 >= path.startDay }) ?? true,
                  path.status != .completed || path.completedDay != nil,
                  path.completedDay == nil || path.status == .completed || path.status == .archived,
                  path.completedDay.map({ $0.isValid && $0 >= path.startDay && pathProgress(path, through: $0) >= 1 }) ?? true else { throw LifeError.invalidValue }
            for milestone in path.milestones {
                try Habit(title: milestone.title, goalType: milestone.goalType, target: milestone.target).validate()
                guard milestone.habitID == nil || habits.contains(where: { $0.id == milestone.habitID }),
                      milestoneValue(milestone, in: path).isFinite else { throw LifeError.invalidValue }
            }
        }
        var keys: Set<String> = []
        for entry in pathEntries {
            guard let path = paths.first(where: { $0.milestones.contains(where: { $0.id == entry.milestoneID }) }),
                  let milestone = path.milestones.first(where: { $0.id == entry.milestoneID }), milestone.habitID == nil,
                  entry.day.isValid, entry.day >= path.startDay, entry.value.isFinite, entry.value >= 0,
                  milestone.goalType != .binary || [0, 1].contains(entry.value),
                  milestone.goalType != .count || entry.value.rounded() == entry.value,
                  keys.insert(entry.milestoneID.uuidString + entry.day.rawValue).inserted else { throw LifeError.invalidValue }
        }
    }
}
extension LifeStore {
    public func savePath(_ path: LifePath) throws {
        var clean = path
        clean.title = clean.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = state.paths.first(where: { $0.id == path.id }) {
            // The source/unit/start date is a contribution contract. Preserve it when editing.
            guard clean.startDay == existing.startDay, clean.status == existing.status, clean.completedDay == existing.completedDay,
                  existing.milestones.allSatisfy({ old in clean.milestones.contains { $0.id == old.id && $0.habitID == old.habitID && $0.goalType == old.goalType } }) else { throw LifeError.invalidValue }
        }
        for milestone in clean.milestones {
            let alreadyLinked = state.paths.flatMap(\.milestones).contains { $0.id == milestone.id }
            if !alreadyLinked, let habitID = milestone.habitID {
                guard state.habits.contains(where: { $0.id == habitID && $0.goalType == milestone.goalType && !$0.isArchived }) else { throw LifeError.invalidValue }
            }
        }
        try transaction { state in
            if let index = state.paths.firstIndex(where: { $0.id == clean.id }) { state.paths[index] = clean }
            else {
                guard clean.status == .active, clean.completedDay == nil else { throw LifeError.invalidValue }
                state.paths.append(clean)
            }
        }
    }
    public func setPathStatus(id: UUID, status: PathStatus, on date: Date = Date(), calendar: Calendar = .current) throws {
        try transaction { state in
            guard let index = state.paths.firstIndex(where: { $0.id == id }) else { throw LifeError.invalidValue }
            if status == .completed {
                let day = DayKey(date: date, calendar: calendar)
                guard state.pathProgress(state.paths[index], through: day) >= 1 else { throw LifeError.invalidValue }
                state.paths[index].completedDay = day
            } else if status != .archived { state.paths[index].completedDay = nil }
            state.paths[index].status = status
        }
    }
    public func recordPathEntry(milestoneID: UUID, value: Double, on date: Date = Date(), calendar: Calendar = .current) throws {
        guard let path = state.paths.first(where: { $0.milestones.contains(where: { $0.id == milestoneID && $0.habitID == nil }) }),
              path.status == .active else { throw LifeError.invalidValue }
        let day = DayKey(date: date, calendar: calendar)
        try transaction { state in
            if let index = state.pathEntries.firstIndex(where: { $0.milestoneID == milestoneID && $0.day == day }) { state.pathEntries[index].value = value }
            else { state.pathEntries.append(PathEntry(milestoneID: milestoneID, day: day, value: value)) }
        }
    }
}

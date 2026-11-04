import Foundation

public enum DemoMemberRole: String, Codable, CaseIterable, Sendable { case member, moderator }
/// Every member is explicitly simulated. There are no remote identity IDs.
public struct CircleDemoMember: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var role: DemoMemberRole
    public init(id: UUID = UUID(), name: String, role: DemoMemberRole = .member) { self.id = id; self.name = name; self.role = role }
}
public struct LocalCircle: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var notes: String
    public var includeDemoContributions: Bool
    public var members: [CircleDemoMember]
    public init(id: UUID = UUID(), title: String, notes: String = "", members: [CircleDemoMember] = [], includeDemoContributions: Bool = true) {
        self.id = id; self.title = title; self.notes = notes; self.members = members; self.includeDemoContributions = includeDemoContributions
    }
}
public enum CircleChallengeStatus: String, Codable, CaseIterable, Sendable { case active, completed, archived }
public struct CircleChallenge: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let circleID: UUID
    public var title: String
    public var notes: String
    public let startDay: DayKey
    public var endDay: DayKey
    public let kind: GoalType
    public let unit: String
    public var target: Double
    public var status: CircleChallengeStatus
    public var completedDay: DayKey?
    public init(id: UUID = UUID(), circleID: UUID, title: String, notes: String = "", startDay: DayKey,
                endDay: DayKey, kind: GoalType = .duration, unit: String = "", target: Double) {
        self.id = id; self.circleID = circleID; self.title = title; self.notes = notes
        self.startDay = startDay; self.endDay = endDay; self.kind = kind; self.unit = unit; self.target = target
        self.status = .active; self.completedDay = nil
    }
}
public enum CircleContributionSource: Codable, Equatable, Sendable {
    case manual(Double)
    /// Explicit grant to this one stored completion, including subsequent corrections.
    case habitCompletion(UUID)
}
public struct CircleContribution: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let challengeID: UUID
    public let day: DayKey
    /// nil is the local owner. Non-nil always refers to an explicitly simulated demo member.
    public let demoMemberID: UUID?
    public var source: CircleContributionSource
    public var isShared: Bool
    public init(id: UUID = UUID(), challengeID: UUID, day: DayKey, demoMemberID: UUID? = nil,
                source: CircleContributionSource, isShared: Bool = false) {
        self.id = id; self.challengeID = challengeID; self.day = day; self.demoMemberID = demoMemberID
        self.source = source; self.isShared = isShared
    }
}
public struct CircleProgress: Equatable, Sendable {
    public let own: Double
    public let demo: Double
    public var total: Double { own + demo }
}
extension LifeState {
    public func circleContributionValue(_ contribution: CircleContribution) -> Double {
        switch contribution.source {
        case .manual(let value): return value
        case .habitCompletion(let id): return completions.first { $0.id == id }?.actualValue ?? 0
        }
    }
    public func circleProgress(_ challenge: CircleChallenge, through day: DayKey? = nil) -> CircleProgress {
        guard let circle = circles.first(where: { $0.id == challenge.circleID }) else { return CircleProgress(own: 0, demo: 0) }
        let contributions = circleContributions.filter { $0.challengeID == challenge.id && $0.isShared && (day == nil || $0.day <= day!) }
        let own = contributions.filter { $0.demoMemberID == nil }.reduce(0) { $0 + circleContributionValue($1) }
        let demo = circle.includeDemoContributions ? contributions.filter { $0.demoMemberID != nil }.reduce(0) { $0 + circleContributionValue($1) } : 0
        return CircleProgress(own: own, demo: demo)
    }
    func validateCircles() throws {
        guard Set(circles.map(\.id)).count == circles.count,
              Set(circles.flatMap(\.members).map(\.id)).count == circles.flatMap(\.members).count,
              Set(circleChallenges.map(\.id)).count == circleChallenges.count,
              Set(circleContributions.map(\.id)).count == circleContributions.count else { throw LifeError.corruptStore }
        for circle in circles {
            guard !circle.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  circle.members.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { throw LifeError.invalidValue }
        }
        for challenge in circleChallenges {
            try Habit(title: challenge.title, goalType: challenge.kind, target: challenge.target).validate()
            guard circles.contains(where: { $0.id == challenge.circleID }), challenge.target <= 1_000_000_000,
                  challenge.startDay.isValid, challenge.endDay.isValid, challenge.endDay >= challenge.startDay,
                  challenge.status != .completed || challenge.completedDay != nil,
                  challenge.status != .active || challenge.completedDay == nil,
                  challenge.completedDay.map({ $0.isValid && $0 >= challenge.startDay }) ?? true,
                  circleProgress(challenge).total.isFinite else { throw LifeError.invalidValue }
        }
        var keys: Set<String> = []
        for entry in circleContributions {
            guard let challenge = circleChallenges.first(where: { $0.id == entry.challengeID }),
                  let circle = circles.first(where: { $0.id == challenge.circleID }),
                  entry.day.isValid, entry.day >= challenge.startDay, entry.day <= challenge.endDay,
                  challenge.completedDay.map({ entry.day <= $0 }) ?? true,
                  entry.demoMemberID == nil || circle.members.contains(where: { $0.id == entry.demoMemberID }) else { throw LifeError.invalidValue }
            let sourceKey: String
            switch entry.source {
            case .manual(let value):
                guard value <= 1_000_000_000 else { throw LifeError.invalidValue }
                sourceKey = "manual:" + (entry.demoMemberID?.uuidString ?? "owner") + entry.day.rawValue
            case .habitCompletion(let id):
                guard entry.demoMemberID == nil, let completion = completions.first(where: { $0.id == id }),
                      completion.day == entry.day, completion.goalTypeSnapshot == challenge.kind else { throw LifeError.invalidValue }
                sourceKey = "habit:" + id.uuidString
            }
            let value = circleContributionValue(entry)
            guard value.isFinite, value >= 0,
                  challenge.kind != .binary || [0, 1].contains(value),
                  challenge.kind != .count || value.rounded() == value,
                  keys.insert(challenge.id.uuidString + sourceKey).inserted else { throw LifeError.invalidValue }
        }
    }
}
extension LifeStore {
    public func saveCircle(_ circle: LocalCircle) throws {
        try transaction { state in
            if let index = state.circles.firstIndex(where: { $0.id == circle.id }) { state.circles[index] = circle }
            else { state.circles.append(circle) }
        }
    }
    public func saveCircleChallenge(_ challenge: CircleChallenge) throws {
        if let old = state.circleChallenges.first(where: { $0.id == challenge.id }) {
            guard old.circleID == challenge.circleID, old.startDay == challenge.startDay, old.kind == challenge.kind,
                  old.unit == challenge.unit, old.status == challenge.status, old.completedDay == challenge.completedDay else { throw LifeError.invalidValue }
        } else { guard challenge.status == .active, challenge.completedDay == nil else { throw LifeError.invalidValue } }
        try transaction { state in
            if let index = state.circleChallenges.firstIndex(where: { $0.id == challenge.id }) { state.circleChallenges[index] = challenge }
            else { state.circleChallenges.append(challenge) }
        }
    }
    public func recordCircleContribution(challengeID: UUID, day: DayKey, demoMemberID: UUID? = nil,
                                         source: CircleContributionSource, shared: Bool = false, today: DayKey = DayKey(date: Date())) throws {
        guard let challenge = state.circleChallenges.first(where: { $0.id == challengeID }), challenge.status == .active,
              today.isValid, day <= today else { throw LifeError.invalidValue }
        if case .habitCompletion(let id) = source {
            guard demoMemberID == nil, let completion = state.completions.first(where: { $0.id == id }),
                  completion.day == day, completion.goalTypeSnapshot == challenge.kind else { throw LifeError.invalidValue }
        }
        try transaction { state in
            let existing = state.circleContributions.firstIndex { entry in
                guard entry.challengeID == challengeID else { return false }
                switch (entry.source, source) {
                case (.manual, .manual): return entry.day == day && entry.demoMemberID == demoMemberID
                case (.habitCompletion(let a), .habitCompletion(let b)): return a == b
                default: return false
                }
            }
            if let index = existing {
                state.circleContributions[index].source = source; state.circleContributions[index].isShared = shared
            } else { state.circleContributions.append(CircleContribution(challengeID: challengeID, day: day, demoMemberID: demoMemberID, source: source, isShared: shared)) }
        }
    }
    /// Revocation is always possible, including archived/completed challenges; private source is untouched.
    public func revokeCircleContribution(id: UUID) throws {
        try transaction { state in
            guard let index = state.circleContributions.firstIndex(where: { $0.id == id }) else { throw LifeError.invalidValue }
            state.circleContributions[index].isShared = false
        }
    }
    public func deleteCircleContribution(id: UUID) throws { try transaction { $0.circleContributions.removeAll { $0.id == id } } }
    public func closeCircleChallenge(id: UUID, archive: Bool = false, today: DayKey = DayKey(date: Date())) throws {
        try transaction { state in
            guard let index = state.circleChallenges.firstIndex(where: { $0.id == id }) else { throw LifeError.invalidValue }
            if !archive {
                guard state.circleChallenges[index].status == .active else { throw LifeError.invalidValue }
                state.circleChallenges[index].completedDay = today
            }
            state.circleChallenges[index].status = archive ? .archived : .completed
        }
    }
    public func deleteCircleChallenge(id: UUID) throws {
        try transaction { state in
            state.circleContributions.removeAll { $0.challengeID == id }
            state.circleChallenges.removeAll { $0.id == id }
        }
    }
}

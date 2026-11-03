import Foundation

public enum AdaptiveDecision: String, Codable, Sendable { case pending, accepted, declined, reverted }
public struct AdaptiveEntry: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID { habitID }
    public let habitID: UUID
    public let titleSnapshot: String
    public let originalTarget: Double
    public let suggestedTarget: Double
    public let isProtected: Bool
    public let supportsPath: Bool
    public var decision: AdaptiveDecision = .pending
    public var acceptedTarget: Double?
    public var effectiveTarget: Double { decision == .accepted ? (acceptedTarget ?? originalTarget) : originalTarget }
}
public struct DailyAdaptivePlan: Identifiable, Codable, Equatable, Sendable {
    public var id: DayKey { day }
    public let day: DayKey
    public let availableMinutes: Int
    public let energy: Int
    public let load: Int
    public let routineMinutes: Double
    public let unknownDurationCount: Int
    public var entries: [AdaptiveEntry]
    public var suggestedMinutes: Double { routineMinutes + entries.reduce(0) { $0 + $1.suggestedTarget } }
    public var effectiveMinutes: Double { routineMinutes + entries.reduce(0) { $0 + $1.effectiveTarget } }
    public var exceedsBudget: Bool { effectiveMinutes > Double(availableMinutes) }
}

/// Pure deterministic planning. Fixed routines/protected habits are never silently reduced.
/// Unknown durations are reported separately, so the time estimate is not a false guarantee.
public enum AdaptiveEngine {
    public static func propose(state: LifeState, habits: [Habit], routines: [Routine], day: DayKey,
                               availableMinutes: Int, energy: Int, load: Int, protectedIDs: Set<UUID> = []) throws -> DailyAdaptivePlan {
        guard (0...1440).contains(availableMinutes), (1...5).contains(energy), (1...5).contains(load),
              protectedIDs.isSubset(of: Set(habits.map(\.id))) else { throw LifeError.invalidValue }
        let sources = habits.map { habit -> (Habit, GoalType, Double) in
            let snapshot = state.completions.first { $0.habitID == habit.id && $0.day == day }
            return (habit, snapshot?.goalTypeSnapshot ?? habit.goalType, snapshot?.targetSnapshot ?? habit.target)
        }
        let duration = sources.filter { $0.1 == .duration }
        let steps = routines.flatMap { routine in state.routineSessions.first { $0.routineID == routine.id && $0.day == day }?.steps ?? routine.steps }
        let routineMinutes = steps.reduce(0.0) { $0 + Double($1.minutes ?? 0) }
        let fixed = routineMinutes + duration.filter { protectedIDs.contains($0.0.id) }.reduce(0) { $0 + $1.2 }
        let prioritized = Set(state.paths.filter { $0.status == .active }.flatMap(\.milestones).compactMap(\.habitID))
        let flexible = duration.filter { !protectedIDs.contains($0.0.id) }
        let factor = min(1, Double(energy) / 3, Double(6 - load) / 3)
        let budget = max(0, Double(availableMinutes) * factor - fixed)
        let weight = flexible.reduce(0.0) { $0 + $1.2 * (prioritized.contains($1.0.id) ? 2 : 1) }
        let entries = duration.map { habit, _, target in
            let protected = protectedIDs.contains(habit.id)
            let share = weight > 0 ? budget * target * (prioritized.contains(habit.id) ? 2 : 1) / weight : 0
            let suggestion = protected ? target : min(target, share.rounded(.down))
            return AdaptiveEntry(habitID: habit.id, titleSnapshot: habit.title, originalTarget: target,
                                 suggestedTarget: suggestion, isProtected: protected, supportsPath: prioritized.contains(habit.id))
        }
        return DailyAdaptivePlan(day: day, availableMinutes: availableMinutes, energy: energy, load: load,
                                 routineMinutes: routineMinutes,
                                 unknownDurationCount: sources.filter { $0.1 != .duration }.count + steps.filter { $0.minutes == nil }.count,
                                 entries: entries)
    }
}
extension LifeState {
    public func adaptiveEntry(habitID: UUID, day: DayKey) -> AdaptiveEntry? {
        adaptivePlans.first { $0.day == day }?.entries.first { $0.habitID == habitID }
    }
    func validateAdaptive() throws {
        guard Set(adaptivePlans.map(\.day)).count == adaptivePlans.count else { throw LifeError.corruptStore }
        for plan in adaptivePlans {
            guard plan.day.isValid, (0...1440).contains(plan.availableMinutes), (1...5).contains(plan.energy), (1...5).contains(plan.load),
                  plan.routineMinutes.isFinite, plan.routineMinutes >= 0, plan.unknownDurationCount >= 0,
                  Set(plan.entries.map(\.habitID)).count == plan.entries.count,
                  plan.suggestedMinutes.isFinite, plan.effectiveMinutes.isFinite else { throw LifeError.invalidValue }
            for entry in plan.entries {
                guard habits.contains(where: { $0.id == entry.habitID }), !entry.titleSnapshot.isEmpty,
                      entry.originalTarget.isFinite, entry.originalTarget > 0,
                      entry.suggestedTarget.isFinite, (0...entry.originalTarget).contains(entry.suggestedTarget),
                      entry.acceptedTarget.map({ $0.isFinite && (0...entry.originalTarget).contains($0) }) ?? true,
                      (entry.decision == .accepted) == (entry.acceptedTarget != nil),
                      !entry.isProtected || (entry.suggestedTarget == entry.originalTarget && entry.effectiveTarget == entry.originalTarget) else { throw LifeError.invalidValue }
                if let completion = completions.first(where: { $0.habitID == entry.habitID && $0.day == plan.day }) {
                    guard completion.goalTypeSnapshot == .duration, completion.targetSnapshot == entry.originalTarget else { throw LifeError.invalidValue }
                }
            }
        }
    }
}
extension LifeStore {
    /// One frozen plan per day. Repeated taps never discard decisions or replace original targets.
    public func createAdaptivePlan(availableMinutes: Int, energy: Int, load: Int, protectedIDs: Set<UUID> = [], on date: Date = Date(), calendar: Calendar = .current) throws {
        let day = DayKey(date: date, calendar: calendar)
        guard !state.adaptivePlans.contains(where: { $0.day == day }) else { return }
        let plan = try AdaptiveEngine.propose(state: state, habits: dueHabits(on: date, calendar: calendar),
                                             routines: dueRoutines(on: date, calendar: calendar), day: day,
                                             availableMinutes: availableMinutes, energy: energy, load: load, protectedIDs: protectedIDs)
        try transaction { $0.adaptivePlans.append(plan) }
    }
    public func decideAdaptive(day: DayKey, habitID: UUID, decision: AdaptiveDecision, target: Double? = nil,
                               now: Date = Date(), calendar: Calendar = .current) throws {
        guard day == DayKey(date: now, calendar: calendar), decision != .pending else { throw LifeError.invalidValue }
        try transaction { state in
            guard let p = state.adaptivePlans.firstIndex(where: { $0.day == day }),
                  let e = state.adaptivePlans[p].entries.firstIndex(where: { $0.habitID == habitID }) else { throw LifeError.missingHabit }
            let entry = state.adaptivePlans[p].entries[e]
            let value = target ?? entry.suggestedTarget
            guard !entry.isProtected || decision != .accepted || value == entry.originalTarget else { throw LifeError.invalidValue }
            state.adaptivePlans[p].entries[e].decision = decision
            state.adaptivePlans[p].entries[e].acceptedTarget = decision == .accepted ? value : nil
        }
    }
}

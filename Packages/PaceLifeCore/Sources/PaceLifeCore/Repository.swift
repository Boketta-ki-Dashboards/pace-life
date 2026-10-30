import Foundation

public enum LifeError: Error, Equatable, Sendable {
    case invalidTitle, invalidGoal, invalidSchedule, missingHabit, missingMode, invalidValue
    case invalidWidgets, invalidActivationDate, corruptStore, unsupportedSchema(Int)
}

@MainActor public protocol StateRepository {
    func load() throws -> LifeState
    func save(_ state: LifeState) throws
}

/// Single-writer repository owned by the main-actor application service.
/// Atomic replacement prevents partial JSON writes. A failed/corrupt read is never replaced by empty data.
@MainActor public final class JSONStateRepository: StateRepository {
    public let url: URL
    private struct Envelope: Codable {
        let schemaVersion: Int
        let state: LifeState
    }
    public init(url: URL) { self.url = url }

    public func load() throws -> LifeState {
        guard FileManager.default.fileExists(atPath: url.path) else { return LifeState() }
        let data = try Data(contentsOf: url)
        // Inspect the schema before decoding models so a future document isn't mistaken for corruption.
        struct Header: Decodable { let schemaVersion: Int }
        let decoder = JSONDecoder()
        let version: Int
        do { version = try decoder.decode(Header.self, from: data).schemaVersion }
        catch { throw LifeError.corruptStore }
        guard version == 1 else { throw LifeError.unsupportedSchema(version) }
        do {
            let state = try decoder.decode(Envelope.self, from: data).state
            try state.validate()
            return state
        } catch { throw LifeError.corruptStore }
    }

    public func save(_ state: LifeState) throws {
        try state.validate()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(Envelope(schemaVersion: 1, state: state))
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        #if os(iOS)
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        #else
        try data.write(to: url, options: [.atomic])
        #endif
    }
}

@MainActor public final class MemoryStateRepository: StateRepository {
    private var state: LifeState
    public init(state: LifeState = LifeState()) { self.state = state }
    public func load() throws -> LifeState { state }
    public func save(_ state: LifeState) throws { try state.validate(); self.state = state }
}

extension LifeState {
    func validate() throws {
        guard Set(habits.map(\.id)).count == habits.count,
              Set(modes.map(\.id)).count == modes.count,
              Set(completions.map(\.id)).count == completions.count,
              Set(activations.map(\.id)).count == activations.count,
              activeModeID == nil || modes.contains(where: { $0.id == activeModeID }) else {
            throw LifeError.corruptStore
        }
        for habit in habits { try habit.validate() }
        for mode in modes {
            guard !mode.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  mode.habitIDs.isSubset(of: Set(habits.map(\.id))) else { throw LifeError.corruptStore }
        }
        var keys: Set<String> = []
        for completion in completions {
            guard habits.contains(where: { $0.id == completion.habitID }),
                  completion.targetSnapshot.isFinite, completion.targetSnapshot > 0,
                  completion.actualValue.isFinite, completion.actualValue >= 0,
                  completion.goalTypeSnapshot != .binary || (completion.targetSnapshot == 1 && [0, 1].contains(completion.actualValue)),
                  completion.goalTypeSnapshot != .count || (completion.targetSnapshot.rounded() == completion.targetSnapshot && completion.actualValue.rounded() == completion.actualValue),
                  completion.day.isValid,
                  TimeZone(identifier: completion.timeZoneID) != nil,
                  keys.insert(completion.habitID.uuidString + completion.day.rawValue).inserted else {
                throw LifeError.corruptStore
            }
        }
        let open = activations.filter { $0.end == nil }
        guard (activeModeID == nil && open.isEmpty) || (open.count == 1 && open[0].modeID == activeModeID) else {
            throw LifeError.corruptStore
        }
        for (index, activation) in activations.enumerated() {
            guard activation.start.timeIntervalSinceReferenceDate.isFinite,
                  !activation.titleSnapshot.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw LifeError.corruptStore }
            if let end = activation.end {
                guard end.timeIntervalSinceReferenceDate.isFinite, end >= activation.start else { throw LifeError.corruptStore }
            }
            if index > 0 {
                guard let previousEnd = activations[index - 1].end, previousEnd <= activation.start else { throw LifeError.corruptStore }
            }
        }
        try Self.validateWidgets(widgets)
    }

    static func validateWidgets(_ widgets: [HomeWidgetPreference]) throws {
        guard widgets.count == HomeWidgetKind.allCases.count,
              Set(widgets.map(\.kind)) == Set(HomeWidgetKind.allCases) else { throw LifeError.invalidWidgets }
    }
}

extension Habit {
    func validate() throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw LifeError.invalidTitle }
        guard target.isFinite, target > 0,
              goalType != .binary || target == 1,
              goalType != .count || target.rounded() == target else { throw LifeError.invalidGoal }
        guard !weekdays.isEmpty, weekdays.isSubset(of: Set(1...7)), createdAt.timeIntervalSinceReferenceDate.isFinite else { throw LifeError.invalidSchedule }
    }
}

private extension DayKey {
    var isValid: Bool {
        guard rawValue.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil else { return false }
        let pieces = rawValue.split(separator: "-").compactMap { Int($0) }
        guard pieces.count == 3, (1...9999).contains(pieces[0]) else { return false }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let date = calendar.date(from: DateComponents(year: pieces[0], month: pieces[1], day: pieces[2])) else { return false }
        return DayKey(date: date, calendar: calendar) == self
    }
}

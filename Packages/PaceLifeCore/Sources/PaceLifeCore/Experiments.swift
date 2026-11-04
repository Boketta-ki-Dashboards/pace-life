import Foundation

public enum ExperimentMetricKind: String, Codable, CaseIterable, Sendable { case number, duration, rating, binary }
public enum ExperimentStatus: String, Codable, CaseIterable, Sendable { case active, completed, archived }
public struct ExperimentMetric: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var kind: ExperimentMetricKind
    public var unit: String
    public var scaleMinimum: Double
    public var scaleMaximum: Double
    public var baseline: Double?
    public init(id: UUID = UUID(), title: String, kind: ExperimentMetricKind = .number, unit: String = "",
                scaleMinimum: Double = 1, scaleMaximum: Double = 10, baseline: Double? = nil) {
        self.id = id; self.title = title; self.kind = kind; self.unit = unit
        self.scaleMinimum = scaleMinimum; self.scaleMaximum = scaleMaximum; self.baseline = baseline
    }
    public func accepts(_ value: Double) -> Bool {
        guard value.isFinite, abs(value) <= 1_000_000_000 else { return false }
        switch kind {
        case .number: return true
        case .duration: return value >= 0
        case .binary: return value == 0 || value == 1
        case .rating: return value >= scaleMinimum && value <= scaleMaximum && value.rounded() == value
        }
    }
}
public struct LifeExperiment: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var question: String
    public var context: String
    public let startDay: DayKey
    public var endDay: DayKey
    public var metrics: [ExperimentMetric]
    public var habitIDs: Set<UUID>
    public var reflection: String
    public var status: ExperimentStatus
    public var completedDay: DayKey?
    public init(id: UUID = UUID(), title: String, question: String = "", context: String = "", startDay: DayKey,
                endDay: DayKey, metrics: [ExperimentMetric], habitIDs: Set<UUID> = []) {
        self.id = id; self.title = title; self.question = question; self.context = context
        self.startDay = startDay; self.endDay = endDay; self.metrics = metrics; self.habitIDs = habitIDs
        self.reflection = ""; self.status = .active; self.completedDay = nil
    }
    public var plannedDays: Int { startDay.distance(to: endDay) + 1 }
}
public struct ExperimentValue: Codable, Equatable, Sendable {
    public let metricID: UUID
    public var value: Double
    public init(metricID: UUID, value: Double) { self.metricID = metricID; self.value = value }
}
public struct ExperimentCheckIn: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let experimentID: UUID
    public let day: DayKey
    public var values: [ExperimentValue]
    public var notes: String
    public init(id: UUID = UUID(), experimentID: UUID, day: DayKey, values: [ExperimentValue], notes: String = "") {
        self.id = id; self.experimentID = experimentID; self.day = day; self.values = values; self.notes = notes
    }
}
public struct ExperimentObservation: Identifiable, Equatable, Sendable {
    public var id: DayKey { day }
    public let day: DayKey
    public let value: Double
}
public struct ExperimentSummary: Equatable, Sendable {
    public let samples: [ExperimentObservation]
    public let expectedDays: Int
    public let baseline: Double?
    public var missingDays: Int { max(0, expectedDays - samples.count) }
    public var mean: Double? { samples.isEmpty ? nil : samples.reduce(0) { $0 + $1.value } / Double(samples.count) }
    public var lastValue: Double? { samples.last?.value }
    public var changeFromBaseline: Double? { guard let baseline, let lastValue else { return nil }; return lastValue - baseline }
}
extension DayKey {
    /// Stored keys always use Gregorian years, even when the device's calendar
    /// is Buddhist or Japanese. Only its time zone influences the editor date.
    public func localDate(calendar: Calendar = .current) -> Date? {
        guard isValid else { return nil }
        let c = rawValue.split(separator: "-").compactMap { Int($0) }
        var civil = Calendar(identifier: .gregorian); civil.timeZone = calendar.timeZone
        return civil.date(from: DateComponents(year: c[0], month: c[1], day: c[2], hour: 12))
    }
    /// Civil arithmetic in UTC: no DST drift and no reinterpretation of stored day labels.
    public var civilDate: Date? {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return localDate(calendar: calendar)
    }
    public func adding(days: Int) -> DayKey? {
        guard let date = civilDate else { return nil }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(byAdding: .day, value: days, to: date).map { DayKey(date: $0, calendar: calendar) }
    }
    public func distance(to other: DayKey) -> Int {
        guard let first = civilDate, let last = other.civilDate else { return 0 }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.dateComponents([.day], from: first, to: last).day ?? 0
    }
}
extension LifeState {
    public func experimentSummary(_ experiment: LifeExperiment, metric: ExperimentMetric, through today: DayKey) -> ExperimentSummary {
        let last = min(today, experiment.completedDay ?? experiment.endDay, experiment.endDay)
        let samples = experimentCheckIns.filter { $0.experimentID == experiment.id && $0.day <= last }.compactMap { check -> ExperimentObservation? in
            guard let value = check.values.first(where: { $0.metricID == metric.id })?.value else { return nil }
            return ExperimentObservation(day: check.day, value: value)
        }.sorted { $0.day < $1.day }
        return ExperimentSummary(samples: samples, expectedDays: max(0, experiment.startDay.distance(to: last) + 1), baseline: metric.baseline)
    }
    func validateExperiments() throws {
        guard Set(experiments.map(\.id)).count == experiments.count,
              Set(experiments.flatMap(\.metrics).map(\.id)).count == experiments.flatMap(\.metrics).count,
              Set(experimentCheckIns.map(\.id)).count == experimentCheckIns.count else { throw LifeError.corruptStore }
        for experiment in experiments {
            guard !experiment.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  experiment.startDay.isValid, experiment.endDay.isValid, experiment.endDay >= experiment.startDay,
                  experiment.plannedDays <= 3660, !experiment.metrics.isEmpty,
                  experiment.habitIDs.isSubset(of: Set(habits.map(\.id))),
                  experiment.status != .completed || experiment.completedDay != nil,
                  experiment.status != .active || experiment.completedDay == nil,
                  experiment.completedDay.map({ $0.isValid && $0 >= experiment.startDay }) ?? true else { throw LifeError.invalidValue }
            for metric in experiment.metrics {
                guard !metric.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      metric.scaleMinimum.isFinite, metric.scaleMaximum.isFinite,
                      metric.scaleMinimum >= 0, metric.scaleMaximum <= 100, metric.scaleMaximum > metric.scaleMinimum,
                      metric.scaleMinimum.rounded() == metric.scaleMinimum, metric.scaleMaximum.rounded() == metric.scaleMaximum,
                      metric.baseline.map(metric.accepts) ?? true else { throw LifeError.invalidValue }
            }
        }
        var keys: Set<String> = []
        for check in experimentCheckIns {
            guard let experiment = experiments.first(where: { $0.id == check.experimentID }),
                  check.day.isValid, check.day >= experiment.startDay, check.day <= experiment.endDay,
                  experiment.completedDay.map({ check.day <= $0 }) ?? true,
                  Set(check.values.map(\.metricID)).count == check.values.count,
                  keys.insert(check.experimentID.uuidString + check.day.rawValue).inserted else { throw LifeError.invalidValue }
            for value in check.values {
                guard let metric = experiment.metrics.first(where: { $0.id == value.metricID }), metric.accepts(value.value) else { throw LifeError.invalidValue }
            }
        }
    }
}
extension LifeStore {
    public func saveExperiment(_ experiment: LifeExperiment) throws {
        if let old = state.experiments.first(where: { $0.id == experiment.id }) {
            // Preserve measurement meaning and baseline; edits cannot relabel historical values.
            guard old.startDay == experiment.startDay, old.metrics == experiment.metrics,
                  old.status == experiment.status, old.completedDay == experiment.completedDay else { throw LifeError.invalidValue }
        } else {
            guard experiment.status == .active, experiment.completedDay == nil else { throw LifeError.invalidValue }
        }
        try transaction { state in
            if let index = state.experiments.firstIndex(where: { $0.id == experiment.id }) { state.experiments[index] = experiment }
            else { state.experiments.append(experiment) }
        }
    }
    public func recordExperiment(id: UUID, day: DayKey, values: [ExperimentValue], notes: String = "", today: DayKey = DayKey(date: Date())) throws {
        guard let experiment = state.experiments.first(where: { $0.id == id }), experiment.status != .archived,
              today.isValid, day <= today else { throw LifeError.invalidValue }
        try transaction { state in
            if let index = state.experimentCheckIns.firstIndex(where: { $0.experimentID == id && $0.day == day }) {
                state.experimentCheckIns[index].values = values; state.experimentCheckIns[index].notes = notes
            } else { state.experimentCheckIns.append(ExperimentCheckIn(experimentID: id, day: day, values: values, notes: notes)) }
        }
    }
    public func finishExperiment(id: UUID, on day: DayKey = DayKey(date: Date())) throws {
        try transaction { state in
            guard let index = state.experiments.firstIndex(where: { $0.id == id }), state.experiments[index].status == .active else { throw LifeError.invalidValue }
            state.experiments[index].completedDay = day; state.experiments[index].status = .completed
        }
    }
    public func archiveExperiment(id: UUID) throws {
        try transaction { state in
            guard let index = state.experiments.firstIndex(where: { $0.id == id }) else { throw LifeError.invalidValue }
            state.experiments[index].status = .archived
        }
    }
    @discardableResult public func repeatExperiment(id: UUID, starting day: DayKey = DayKey(date: Date())) throws -> UUID {
        guard let old = state.experiments.first(where: { $0.id == id }), let end = day.adding(days: old.plannedDays - 1) else { throw LifeError.invalidValue }
        let metrics = old.metrics.map { ExperimentMetric(title: $0.title, kind: $0.kind, unit: $0.unit, scaleMinimum: $0.scaleMinimum, scaleMaximum: $0.scaleMaximum) }
        let fresh = LifeExperiment(title: old.title, question: old.question, context: old.context,
                                   startDay: day, endDay: end, metrics: metrics, habitIDs: old.habitIDs)
        try saveExperiment(fresh)
        return fresh.id
    }
}

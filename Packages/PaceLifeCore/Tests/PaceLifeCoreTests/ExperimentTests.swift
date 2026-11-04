import Foundation
import XCTest
@testable import PaceLifeCore

final class ExperimentTests: XCTestCase {
    func testStoredDaysMissingDataCorrectionAndBaselineRemainHonest() async throws {
        try await MainActor.run {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            let url = folder.appendingPathComponent("life.json")
            let store = try LifeStore(repository: JSONStateRepository(url: url))
            let start = DayKey(rawValue: "2026-10-20")
            let sleep = ExperimentMetric(title: "Sleep", kind: .duration, baseline: 360)
            let energy = ExperimentMetric(title: "Energy", kind: .rating, baseline: 3)
            let experiment = LifeExperiment(title: "Earlier sleep", startDay: start, endDay: start.adding(days: 13)!, metrics: [sleep, energy])
            try store.saveExperiment(experiment)
            for offset in [0, 1, 3] {
                let day = start.adding(days: offset)!
                try store.recordExperiment(id: experiment.id, day: day, values: [.init(metricID: sleep.id, value: 420), .init(metricID: energy.id, value: 6)], today: day)
            }
            let last = start.adding(days: 3)!
            let restored = try LifeStore(repository: JSONStateRepository(url: url))
            var summary = restored.state.experimentSummary(experiment, metric: sleep, through: last)
            XCTAssertEqual(summary.mean, 420); XCTAssertEqual(summary.missingDays, 1)
            XCTAssertEqual(summary.changeFromBaseline, 60)
            XCTAssertEqual(summary.samples.count, 3)
            try restored.recordExperiment(id: experiment.id, day: last, values: [.init(metricID: sleep.id, value: 480)], today: last)
            XCTAssertEqual(restored.state.experimentCheckIns.count, 3, "Correction replaces the day")
            summary = restored.state.experimentSummary(experiment, metric: energy, through: last)
            XCTAssertEqual(summary.samples.count, 2); XCTAssertEqual(summary.missingDays, 2)
            try restored.finishExperiment(id: experiment.id, on: last)
            let finished = restored.state.experiments[0]
            XCTAssertEqual(restored.state.experimentSummary(finished, metric: sleep, through: start.adding(days: 20)!).expectedDays, 4)
            XCTAssertEqual(try JSONStateRepository(url: url).load(), restored.state)
        }
    }
    func testRepeatCreatesIndependentMetricsAndNoInventedBaselineOrMeasurements() async throws {
        try await MainActor.run {
            let store = try LifeStore(repository: MemoryStateRepository())
            let start = DayKey(rawValue: "2026-10-25")
            let metric = ExperimentMetric(title: "Energy", kind: .rating, baseline: 5)
            let original = LifeExperiment(title: "Focus", startDay: start, endDay: start.adding(days: 6)!, metrics: [metric])
            try store.saveExperiment(original)
            try store.recordExperiment(id: original.id, day: start, values: [.init(metricID: metric.id, value: 7)], today: start)
            try store.finishExperiment(id: original.id, on: start)
            try store.archiveExperiment(id: original.id)
            let id = try store.repeatExperiment(id: original.id, starting: start.adding(days: 7)!)
            let repeated = try XCTUnwrap(store.state.experiments.first { $0.id == id })
            XCTAssertEqual(repeated.plannedDays, 7); XCTAssertEqual(repeated.status, .active)
            XCTAssertNotEqual(repeated.metrics[0].id, metric.id); XCTAssertNil(repeated.metrics[0].baseline)
            XCTAssertEqual(store.state.experimentCheckIns.count, 1)
            XCTAssertTrue(store.state.experimentSummary(repeated, metric: repeated.metrics[0], through: repeated.startDay).samples.isEmpty)
            XCTAssertThrowsError(try store.recordExperiment(id: original.id, day: start, values: [], today: start))
        }
    }
    func testInvalidValuesFutureDatesAndHistoricalRelabelingAreRejected() async throws {
        try await MainActor.run {
            let store = try LifeStore(repository: MemoryStateRepository())
            let start = DayKey(rawValue: "2026-03-28")
            let metric = ExperimentMetric(title: "Rating", kind: .rating, scaleMinimum: 0, scaleMaximum: 5)
            var experiment = LifeExperiment(title: "Trial", startDay: start, endDay: start.adding(days: 6)!, metrics: [metric])
            try store.saveExperiment(experiment)
            for value in [-1, 6, 2.5, Double.infinity, Double.nan] {
                XCTAssertThrowsError(try store.recordExperiment(id: experiment.id, day: start, values: [.init(metricID: metric.id, value: value)], today: start))
            }
            XCTAssertThrowsError(try store.recordExperiment(id: experiment.id, day: start.adding(days: 1)!, values: [], today: start))
            XCTAssertThrowsError(try store.recordExperiment(id: experiment.id, day: start.adding(days: -1)!, values: [], today: start))
            XCTAssertThrowsError(try store.recordExperiment(id: experiment.id, day: start, values: [.init(metricID: metric.id, value: 1), .init(metricID: metric.id, value: 2)], today: start))
            experiment.metrics[0].kind = .duration
            XCTAssertThrowsError(try store.saveExperiment(experiment))
            XCTAssertTrue(store.state.experimentCheckIns.isEmpty)
            XCTAssertEqual(start.distance(to: start.adding(days: 6)!), 6)
            XCTAssertEqual(DayKey(rawValue: "2026-12-31").adding(days: 1)?.rawValue, "2027-01-01")
        }
    }
    func testSchemaFiveRetainsChaptersAndRequiresCurrentExperimentArrays() async throws {
        try await MainActor.run {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appendingPathComponent("life.json")
            let original = LifeState(chapters: [LifeChapter(title: "Private", photoIDs: [UUID()])])
            var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
            legacy.removeValue(forKey: "experiments"); legacy.removeValue(forKey: "experimentCheckIns")
            let data = try JSONSerialization.data(withJSONObject: ["schemaVersion": 5, "state": legacy])
            try data.write(to: url)
            let repo = JSONStateRepository(url: url)
            XCTAssertEqual(try repo.load(), original); XCTAssertEqual(try Data(contentsOf: url), data)
            try repo.save(original); XCTAssertEqual(try JSONStateRepository(url: url).load(), original)
            let corrupt = try JSONSerialization.data(withJSONObject: ["schemaVersion": 6, "state": legacy]); try corrupt.write(to: url)
            XCTAssertThrowsError(try JSONStateRepository(url: url).load())
        }
    }
}

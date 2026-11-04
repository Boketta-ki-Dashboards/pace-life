import Foundation
import XCTest
@testable import PaceLifeCore

final class CircleTests: XCTestCase {
    func testDemoTotalsCorrectionsSettingsAndRevocationSurviveRestart() async throws {
        try await MainActor.run {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            let url = folder.appendingPathComponent("life.json")
            let store = try LifeStore(repository: JSONStateRepository(url: url))
            let day = DayKey(rawValue: "2026-11-04")
            var circle = LocalCircle(title: "Study group", members: (1...4).map { CircleDemoMember(name: "Demo \($0)") })
            try store.saveCircle(circle)
            let challenge = CircleChallenge(circleID: circle.id, title: "100 hours", startDay: day, endDay: day.adding(days: 29)!, target: 6000)
            try store.saveCircleChallenge(challenge)
            for (index, member) in circle.members.enumerated() {
                try store.recordCircleContribution(challengeID: challenge.id, day: day, demoMemberID: member.id, source: .manual(Double(index + 1) * 10), shared: true, today: day)
            }
            try store.recordCircleContribution(challengeID: challenge.id, day: day, source: .manual(25), today: day)
            XCTAssertEqual(store.state.circleProgress(challenge), CircleProgress(own: 0, demo: 100))
            try store.recordCircleContribution(challengeID: challenge.id, day: day, source: .manual(25), shared: true, today: day)
            try store.recordCircleContribution(challengeID: challenge.id, day: day, demoMemberID: circle.members[0].id, source: .manual(50), shared: true, today: day)
            XCTAssertEqual(store.state.circleContributions.count, 5)
            XCTAssertEqual(store.state.circleProgress(challenge), CircleProgress(own: 25, demo: 140))
            let restored = try LifeStore(repository: JSONStateRepository(url: url))
            XCTAssertEqual(restored.state, store.state)
            circle.includeDemoContributions = false; try restored.saveCircle(circle)
            XCTAssertEqual(restored.state.circleProgress(challenge).total, 25)
            try restored.closeCircleChallenge(id: challenge.id, today: day)
            try restored.closeCircleChallenge(id: challenge.id, archive: true)
            let own = try XCTUnwrap(restored.state.circleContributions.first { $0.demoMemberID == nil })
            try restored.revokeCircleContribution(id: own.id)
            XCTAssertEqual(restored.state.circleProgress(challenge).total, 0)
            XCTAssertEqual(try JSONStateRepository(url: url).load(), restored.state)
            try restored.deleteCircleContribution(id: own.id)
            XCTAssertEqual(restored.state.circleContributions.count, 4)
        }
    }
    func testConnectedDailyWorkExperimentChapterAndExplicitCircleGrant() async throws {
        try await MainActor.run {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            let url = folder.appendingPathComponent("life.json")
            let store = try LifeStore(repository: JSONStateRepository(url: url))
            let day = DayKey(rawValue: "2026-11-04"), date = day.civilDate!
            var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            let habit = Habit(title: "Study Russian", goalType: .duration, target: 60, createdAt: date)
            try store.saveHabit(habit)
            let milestone = PathMilestone(title: "Practice", goalType: .duration, target: 60, habitID: habit.id)
            let mode = LifeMode(title: "Workday", habitIDs: [habit.id]); try store.saveMode(mode); try store.activateMode(id: mode.id, at: date)
            let step = RoutineStep(title: "Review", minutes: 5)
            let routine = Routine(title: "Learning", modeID: mode.id, steps: [step], createdAt: date)
            try store.saveRoutine(routine)
            let routineMilestone = PathMilestone(title: "Review session", routineID: routine.id)
            let path = LifePath(title: "Russian B2", startDay: day, milestones: [milestone, routineMilestone]); try store.savePath(path)
            try store.startRoutine(id: routine.id, on: date, calendar: calendar)
            try store.setRoutineStep(sessionID: store.state.routineSessions[0].id, stepID: step.id, completed: true)
            try store.createAdaptivePlan(availableMinutes: 20, energy: 3, load: 3, on: date, calendar: calendar)
            try store.decideAdaptive(day: day, habitID: habit.id, decision: .accepted, target: 15, now: date, calendar: calendar)
            try store.record(habitID: habit.id, value: 15, on: date, calendar: calendar)
            XCTAssertEqual(store.state.milestoneValue(milestone, in: path), 15)
            XCTAssertEqual(store.state.completions[0].targetSnapshot, 60)
            XCTAssertEqual(store.state.milestoneValue(routineMilestone, in: path), 1)
            let metric = ExperimentMetric(title: "Energy", kind: .rating)
            let experiment = LifeExperiment(title: "Learning energy", startDay: day, endDay: day.adding(days: 13)!, metrics: [metric], habitIDs: [habit.id])
            try store.saveExperiment(experiment)
            try store.recordExperiment(id: experiment.id, day: day, values: [.init(metricID: metric.id, value: 7)], today: day)
            try store.saveChapter(LifeChapter(title: "First progress", pathIDs: [path.id], memories: [ChapterMemory(title: "Started", day: day, isMilestone: true)]))
            let circle = LocalCircle(title: "Local learning"); try store.saveCircle(circle)
            let challenge = CircleChallenge(circleID: circle.id, title: "Study together", startDay: day, endDay: day.adding(days: 29)!, target: 6000)
            try store.saveCircleChallenge(challenge)
            let completion = store.state.completions[0]
            try store.recordCircleContribution(challengeID: challenge.id, day: day, source: .habitCompletion(completion.id), today: day)
            XCTAssertEqual(store.state.circleProgress(challenge).total, 0)
            try store.recordCircleContribution(challengeID: challenge.id, day: day, source: .habitCompletion(completion.id), shared: true, today: day)
            XCTAssertEqual(store.state.circleProgress(challenge).total, 15)
            try store.record(habitID: habit.id, value: 12, on: date, calendar: calendar)
            XCTAssertEqual(store.state.circleProgress(challenge).total, 12)
            XCTAssertEqual(store.state.milestoneValue(milestone, in: path), 12)
            XCTAssertEqual(store.state.circleContributions.count, 1)
            let restored = try LifeStore(repository: JSONStateRepository(url: url)); XCTAssertEqual(restored.state, store.state)
            try restored.revokeCircleContribution(id: restored.state.circleContributions[0].id)
            XCTAssertEqual(restored.state.circleProgress(challenge).total, 0)
            XCTAssertEqual(restored.state.completions[0].actualValue, 12)
            XCTAssertEqual(restored.state.experimentCheckIns[0].values[0].value, 7)
            XCTAssertEqual(restored.state.chapters.count, 1)
        }
    }
    func testCircleRejectsInvalidDatesMembersUnitsAndImplicitDemoIdentity() async throws {
        try await MainActor.run {
            let store = try LifeStore(repository: MemoryStateRepository())
            let day = DayKey(rawValue: "2026-11-04")
            let member = CircleDemoMember(name: "Demo")
            let circle = LocalCircle(title: "Local", members: [member]); try store.saveCircle(circle)
            let challenge = CircleChallenge(circleID: circle.id, title: "Read", startDay: day, endDay: day.adding(days: 6)!, kind: .count, unit: "Pages", target: 100)
            try store.saveCircleChallenge(challenge)
            for value in [-1, 1.5, Double.infinity] {
                XCTAssertThrowsError(try store.recordCircleContribution(challengeID: challenge.id, day: day, source: .manual(value), shared: true, today: day))
            }
            XCTAssertThrowsError(try store.recordCircleContribution(challengeID: challenge.id, day: day, demoMemberID: UUID(), source: .manual(1), today: day))
            XCTAssertThrowsError(try store.recordCircleContribution(challengeID: challenge.id, day: day.adding(days: 1)!, source: .manual(1), today: day))
            XCTAssertThrowsError(try store.recordCircleContribution(challengeID: challenge.id, day: day, demoMemberID: member.id, source: .habitCompletion(UUID()), today: day))
            XCTAssertTrue(store.state.circleContributions.isEmpty)
        }
    }
    func testFailedSharingDoesNotPublishAndSchemaSixMigratesWithoutDataLoss() async throws {
        try await MainActor.run {
            let day = DayKey(rawValue: "2026-11-04")
            let circle = LocalCircle(title: "Keep")
            let challenge = CircleChallenge(circleID: circle.id, title: "Keep", startDay: day, endDay: day, target: 10)
            let original = LifeState(circles: [circle], circleChallenges: [challenge])
            let store = try LifeStore(repository: CircleFailingRepository(state: original))
            XCTAssertThrowsError(try store.recordCircleContribution(challengeID: challenge.id, day: day, source: .manual(5), shared: true, today: day))
            XCTAssertEqual(store.state, original)
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appendingPathComponent("life.json")
            let metric = ExperimentMetric(title: "Value")
            let old = LifeState(chapters: [LifeChapter(title: "Private")], experiments: [LifeExperiment(title: "Experiment", startDay: day, endDay: day, metrics: [metric])])
            var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(old)) as? [String: Any])
            for key in ["circles", "circleChallenges", "circleContributions"] { json.removeValue(forKey: key) }
            let data = try JSONSerialization.data(withJSONObject: ["schemaVersion": 6, "state": json]); try data.write(to: url)
            let repo = JSONStateRepository(url: url); XCTAssertEqual(try repo.load(), old)
            XCTAssertEqual(try Data(contentsOf: url), data); try repo.save(old)
            XCTAssertEqual(try JSONStateRepository(url: url).load(), old)
            let corrupt = try JSONSerialization.data(withJSONObject: ["schemaVersion": 7, "state": json]); try corrupt.write(to: url)
            XCTAssertThrowsError(try JSONStateRepository(url: url).load())
        }
    }
}
@MainActor private struct CircleFailingRepository: StateRepository {
    let state: LifeState
    func load() throws -> LifeState { state }
    func save(_ state: LifeState) throws { throw CocoaError(.fileWriteOutOfSpace) }
}

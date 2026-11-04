import Foundation
import XCTest
@testable import PaceLifeCore

final class MigrationTests: XCTestCase {
    func testSchemaOneMigrationIsIdempotentAndWritesStrictCurrentSchema() async throws {
        try await MainActor.run {
            let fixture = try Data(contentsOf: XCTUnwrap(Bundle.module.url(forResource: "schema-one", withExtension: "json", subdirectory: "Fixtures")))
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appendingPathComponent("life.json")
            try fixture.write(to: url)
            let repo = JSONStateRepository(url: url)
            let first = try repo.load()
            XCTAssertEqual(first, try repo.load())
            XCTAssertEqual(try Data(contentsOf: url), fixture)
            XCTAssertTrue(first.routines.isEmpty); XCTAssertTrue(first.routineSessions.isEmpty)
            XCTAssertEqual(first.widgets.first(where: { $0.kind == .routines }), HomeWidgetPreference(kind: .routines, isVisible: false))
            try repo.save(first)
            let saved = try Data(contentsOf: url)
            var json = try XCTUnwrap(JSONSerialization.jsonObject(with: saved) as? [String: Any])
            XCTAssertEqual(json["schemaVersion"] as? Int, 8)
            XCTAssertEqual(first, try JSONStateRepository(url: url).load())
            var state = try XCTUnwrap(json["state"] as? [String: Any])
            state.removeValue(forKey: "routineSessions"); json["state"] = state
            let broken = try JSONSerialization.data(withJSONObject: json)
            try broken.write(to: url)
            XCTAssertThrowsError(try JSONStateRepository(url: url).load())
            XCTAssertThrowsError(try JSONStateRepository(url: url).save(first))
            XCTAssertEqual(try Data(contentsOf: url), broken)
        }
    }
    func testExternalReplacementCannotBeOverwrittenByStaleStore() async throws {
        try await MainActor.run {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            let url = folder.appendingPathComponent("life.json")
            let store = try LifeStore(repository: JSONStateRepository(url: url))
            try store.saveHabit(Habit(title: "Keep"))
            let before = store.state
            let future = Data(#"{"schemaVersion":99,"state":{}}"#.utf8)
            try future.write(to: url)
            XCTAssertThrowsError(try store.setSettings(AppSettings(language: .en)))
            XCTAssertEqual(store.state, before)
            XCTAssertEqual(try Data(contentsOf: url), future)
        }
    }
    func testMigrationWriteFailureLeavesOriginalBytesAndState() async throws {
        try await MainActor.run {
            let fixture = try Data(contentsOf: XCTUnwrap(Bundle.module.url(forResource: "schema-one", withExtension: "json", subdirectory: "Fixtures")))
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appendingPathComponent("life.json")
            try fixture.write(to: url)
            let backing = JSONStateRepository(url: url)
            let store = try LifeStore(repository: MigrationWriteFailure(backing: backing))
            let before = store.state
            XCTAssertThrowsError(try store.saveRoutine(Routine(title: "Morning", steps: [RoutineStep(title: "One")])))
            XCTAssertEqual(store.state, before)
            XCTAssertEqual(try Data(contentsOf: url), fixture)
        }
    }
}
@MainActor private struct MigrationWriteFailure: StateRepository {
    let backing: JSONStateRepository
    func load() throws -> LifeState { try backing.load() }
    func save(_ state: LifeState) throws { throw CocoaError(.fileWriteOutOfSpace) }
}

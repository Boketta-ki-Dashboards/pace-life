import Foundation
import XCTest
@testable import PaceLifeCore

/// Frozen on-disk data written by JSONStateRepository at phase-one commit c2299e5.
/// Do not regenerate this fixture using a later schema: it is the migration baseline.
final class SchemaOneFixtureTests: XCTestCase {
    private static func fixtureData() throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "schema-one", withExtension: "json", subdirectory: "Fixtures"))
        return try Data(contentsOf: url)
    }

    private static func temporaryStore(with data: Data) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("life.json")
        try data.write(to: url)
        return url
    }

    /// New schemas may add fields but must retain every old value and meaningful array order.
    /// Swift Set serialization can reorder only these two specific collections.
    private static func assertPreserves(_ original: Any, in current: Any, path: String = "state",
                                        file: StaticString = #filePath, line: UInt = #line) {
        if let old = original as? [String: Any] {
            guard let new = current as? [String: Any] else { XCTFail("Object lost: \(path)", file: file, line: line); return }
            for (key, value) in old {
                guard let other = new[key] else { XCTFail("Field lost: \(path).\(key)", file: file, line: line); continue }
                assertPreserves(value, in: other, path: path + "." + key, file: file, line: line)
            }
        } else if let old = original as? [Any] {
            guard let new = current as? [Any] else { XCTFail("Array lost: \(path)", file: file, line: line); return }
            if path.hasSuffix(".weekdays") || path.hasSuffix(".habitIDs") {
                XCTAssertEqual(old.map { String(describing: $0) }.sorted(), new.map { String(describing: $0) }.sorted(), path, file: file, line: line)
                return
            }
            // New widget kinds may be appended; the existing preference order must survive.
            if path == "state.widgets" {
                let oldKinds = Set(old.compactMap { ($0 as? [String: Any])?["kind"] as? String })
                let preserved = new.filter { oldKinds.contains(($0 as? [String: Any])?["kind"] as? String ?? "") }
                XCTAssertEqual(old.count, preserved.count, path, file: file, line: line)
                for (a, b) in zip(old, preserved) { assertPreserves(a, in: b, path: path + "[]", file: file, line: line) }
            } else {
                XCTAssertEqual(old.count, new.count, path, file: file, line: line)
                for (a, b) in zip(old, new) { assertPreserves(a, in: b, path: path + "[]", file: file, line: line) }
            }
        } else {
            XCTAssertEqual(original as? NSObject, current as? NSObject, path, file: file, line: line)
        }
    }

    func testFrozenSchemaOneDataLoadsWithoutChangingFileOrLosingAnyLegacyField() async throws {
        try await MainActor.run {
            let original = try Self.fixtureData()
            let url = try Self.temporaryStore(with: original)
            defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
            let store = try LifeStore(repository: JSONStateRepository(url: url))
            let envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: original) as? [String: Any])
            XCTAssertEqual(envelope["schemaVersion"] as? Int, 1)
            Self.assertPreserves(try XCTUnwrap(envelope["state"]), in: try JSONSerialization.jsonObject(with: JSONEncoder().encode(store.state)))
            XCTAssertEqual(try Data(contentsOf: url), original, "Loading/migrating in memory must not rewrite the original file")
            XCTAssertEqual(store.state.settings, AppSettings(theme: .dark, language: .ru))
            XCTAssertEqual(store.state.completions.first?.targetSnapshot, 90)
            XCTAssertEqual(store.state.habits.first?.target, 60, "The old target snapshot deliberately differs from the present habit target")
            XCTAssertTrue(store.state.habits[1].isArchived)
        }
    }

    func testFirstWriteAfterLoadingSchemaOnePreservesHistoryAndWidgetPreferences() async throws {
        try await MainActor.run {
            let original = try Self.fixtureData()
            let url = try Self.temporaryStore(with: original)
            defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
            let store = try LifeStore(repository: JSONStateRepository(url: url))
            let loaded = store.state
            try store.setSettings(AppSettings(theme: .light, language: .en))
            let restored = try LifeStore(repository: JSONStateRepository(url: url))
            XCTAssertEqual(restored.state.habits, loaded.habits)
            XCTAssertEqual(restored.state.completions, loaded.completions)
            XCTAssertEqual(restored.state.modes, loaded.modes)
            XCTAssertEqual(restored.state.activations, loaded.activations)
            XCTAssertEqual(restored.state.activeModeID, loaded.activeModeID)
            XCTAssertEqual(restored.state.widgets, loaded.widgets)
            XCTAssertEqual(restored.state.settings, AppSettings(theme: .light, language: .en))
            let envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: original) as? [String: Any])
            var originalState = try XCTUnwrap(envelope["state"] as? [String: Any])
            originalState["settings"] = ["theme": "light", "language": "en"]
            Self.assertPreserves(originalState, in: try JSONSerialization.jsonObject(with: JSONEncoder().encode(restored.state)))
        }
    }
}

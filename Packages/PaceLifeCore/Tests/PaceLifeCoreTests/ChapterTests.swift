import Foundation
import XCTest
@testable import PaceLifeCore

final class ChapterTests: XCTestCase {
    func testChapterPhotosMemoriesAndArchivedPathSurviveRestart() async throws {
        try await MainActor.run {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            let url = folder.appendingPathComponent("life.json")
            let photos = FileChapterPhotoRepository(directory: folder.appendingPathComponent("photos"))
            let store = try LifeStore(repository: JSONStateRepository(url: url))
            let path = LifePath(title: "Graduation", milestones: [PathMilestone(title: "Exam")])
            try store.savePath(path)
            var chapter = LifeChapter(title: "Graduation", category: .education, pathIDs: [path.id],
                                      memories: [ChapterMemory(title: "Passed", isMilestone: true)])
            try store.saveChapter(chapter)
            for value in 1...3 { try store.importChapterPhoto(Data([UInt8(value)]), chapterID: chapter.id, photos: photos) }
            try store.setPathStatus(id: path.id, status: .archived)
            let restored = try LifeStore(repository: JSONStateRepository(url: url))
            XCTAssertEqual(restored.state, store.state)
            chapter = try XCTUnwrap(restored.state.chapters.first)
            XCTAssertEqual(chapter.photoIDs.count, 3)
            for (index, id) in chapter.photoIDs.enumerated() { XCTAssertEqual(try photos.load(id), Data([UInt8(index + 1)])) }
            XCTAssertEqual(chapter.pathIDs, [path.id]); XCTAssertTrue(chapter.memories[0].isMilestone)
            chapter.title = "My graduation"; chapter.memories[0].notes = "A memorable day"
            chapter.isArchived = true
            try restored.saveChapter(chapter)
            XCTAssertTrue(restored.state.chapterTimeline().isEmpty)
            XCTAssertEqual(restored.state.chapterTimeline(archived: true).count, 1)
            XCTAssertEqual(try JSONStateRepository(url: url).load(), restored.state)
        }
    }
    func testSharedPhotosDeletedOnlyAfterLastReferenceAndMissingFileIsTolerated() async throws {
        try await MainActor.run {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            let photos = FileChapterPhotoRepository(directory: folder)
            let id = try photos.save(Data([1, 2, 3]))
            let first = LifeChapter(title: "First", photoIDs: [id])
            var second = LifeChapter(title: "Second", photoIDs: [id]); second.isArchived = true
            let store = try LifeStore(repository: MemoryStateRepository(state: LifeState(chapters: [first, second])))
            try store.deleteChapter(id: first.id)
            try photos.removeUnreferenced(keeping: store.state.referencedPhotoIDs)
            XCTAssertNotNil(try photos.load(id), "Archive remains a reference")
            try photos.discardNewPhoto(id) // Simulate missing/corrupted external media without changing JSON.
            XCTAssertNil(try photos.load(id)); XCTAssertNoThrow(try store.state.validate())
            try store.deleteChapter(id: second.id)
            XCTAssertNoThrow(try photos.removeUnreferenced(keeping: store.state.referencedPhotoIDs))
            let orphan = try photos.save(Data([9]))
            try photos.removeUnreferenced(keeping: [])
            XCTAssertNil(try photos.load(orphan))
        }
    }
    func testFailedPhotoAttachmentPreservesExistingFileAndRollsBackNewFile() async throws {
        try await MainActor.run {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            let photos = FileChapterPhotoRepository(directory: folder)
            let id = try photos.save(Data([7]))
            let chapter = LifeChapter(title: "Keep", photoIDs: [id])
            let original = LifeState(chapters: [chapter])
            let store = try LifeStore(repository: ChapterFailingRepository(state: original))
            XCTAssertThrowsError(try store.importChapterPhoto(Data([8]), chapterID: chapter.id, photos: photos))
            XCTAssertEqual(store.state, original)
            XCTAssertEqual(try photos.load(id), Data([7]))
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: folder.path).count, 1)
            XCTAssertThrowsError(try store.deleteChapter(id: chapter.id))
            XCTAssertEqual(store.state, original)
        }
    }
    func testChapterValidationAndTimeline() async throws {
        try await MainActor.run {
            let store = try LifeStore(repository: MemoryStateRepository())
            let old = LifeChapter(title: "Old", startDay: DayKey(rawValue: "2020-01-01"))
            var newer = LifeChapter(title: "New", startDay: DayKey(rawValue: "2026-10-25"))
            try store.saveChapter(old); try store.saveChapter(newer)
            XCTAssertEqual(store.state.chapterTimeline().map(\.id), [newer.id, old.id])
            newer.endDay = DayKey(rawValue: "2026-10-24")
            XCTAssertThrowsError(try store.saveChapter(newer))
            newer.endDay = nil; newer.pathIDs = [UUID()]
            XCTAssertThrowsError(try store.saveChapter(newer))
            newer.pathIDs = []; newer.memories = [ChapterMemory(title: "")]
            XCTAssertThrowsError(try store.saveChapter(newer))
            newer.memories = []; let id = UUID(); newer.photoIDs = [id, id]
            XCTAssertThrowsError(try store.saveChapter(newer))
            XCTAssertEqual(store.state.chapters.count, 2)
        }
    }
    func testSchemaFourMigrationPreservesAllFieldsAndCurrentChaptersAreRequired() async throws {
        try await MainActor.run {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            let url = folder.appendingPathComponent("life.json")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let fixture = try Data(contentsOf: XCTUnwrap(Bundle.module.url(forResource: "schema-one", withExtension: "json", subdirectory: "Fixtures")))
            try fixture.write(to: url)
            let old = try LifeStore(repository: JSONStateRepository(url: url))
            try old.saveRoutine(Routine(title: "Practice", steps: [RoutineStep(title: "Read")]))
            try old.savePath(LifePath(title: "Learn", milestones: [PathMilestone(title: "Finish")]))
            var encoded = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(old.state)) as? [String: Any])
            encoded.removeValue(forKey: "chapters")
            let data = try JSONSerialization.data(withJSONObject: ["schemaVersion": 4, "state": encoded])
            try data.write(to: url)
            let repo = JSONStateRepository(url: url)
            let migrated = try repo.load()
            // Schema 4 never stored day plans; every other field is preserved unchanged.
            var expected = old.state; expected.dayPlans = []
            XCTAssertEqual(migrated, expected)
            XCTAssertEqual(try Data(contentsOf: url), data)
            try repo.save(migrated)
            XCTAssertEqual(try JSONStateRepository(url: url).load(), migrated)
            let corrupt = try JSONSerialization.data(withJSONObject: ["schemaVersion": 5, "state": encoded])
            try corrupt.write(to: url)
            XCTAssertThrowsError(try JSONStateRepository(url: url).load())
            XCTAssertEqual(try Data(contentsOf: url), corrupt)
        }
    }
}
@MainActor private struct ChapterFailingRepository: StateRepository {
    let state: LifeState
    func load() throws -> LifeState { state }
    func save(_ state: LifeState) throws { throw CocoaError(.fileWriteOutOfSpace) }
}

import Foundation

public enum ChapterCategory: String, Codable, CaseIterable, Sendable { case personal, education, work, health, travel, relationships }
public struct ChapterMemory: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var notes: String
    public var day: DayKey
    public var isMilestone: Bool
    public init(id: UUID = UUID(), title: String, notes: String = "", day: DayKey = DayKey(date: Date()), isMilestone: Bool = false) {
        self.id = id; self.title = title; self.notes = notes; self.day = day; self.isMilestone = isMilestone
    }
}
/// Private by construction: there is no public visibility or Circle payload on a chapter.
public struct LifeChapter: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var notes: String
    public var startDay: DayKey
    public var endDay: DayKey?
    public var category: ChapterCategory
    public var pathIDs: Set<UUID>
    public var photoIDs: [UUID]
    public var memories: [ChapterMemory]
    public var isArchived: Bool
    public let createdAt: Date
    public var updatedAt: Date
    public init(id: UUID = UUID(), title: String, notes: String = "", startDay: DayKey = DayKey(date: Date()),
                endDay: DayKey? = nil, category: ChapterCategory = .personal, pathIDs: Set<UUID> = [],
                photoIDs: [UUID] = [], memories: [ChapterMemory] = [], createdAt: Date = Date()) {
        self.id = id; self.title = title; self.notes = notes; self.startDay = startDay; self.endDay = endDay
        self.category = category; self.pathIDs = pathIDs; self.photoIDs = photoIDs; self.memories = memories
        self.isArchived = false; self.createdAt = createdAt; self.updatedAt = createdAt
    }
}
extension LifeState {
    public var referencedPhotoIDs: Set<UUID> { Set(chapters.flatMap(\.photoIDs)) }
    public func chapterTimeline(archived: Bool = false) -> [LifeChapter] {
        chapters.filter { $0.isArchived == archived }.sorted {
            if $0.startDay != $1.startDay { return $0.startDay > $1.startDay }
            return $0.id.uuidString < $1.id.uuidString
        }
    }
    func validateChapters() throws {
        let memories = chapters.flatMap(\.memories)
        guard Set(chapters.map(\.id)).count == chapters.count,
              Set(memories.map(\.id)).count == memories.count else { throw LifeError.corruptStore }
        for chapter in chapters {
            guard !chapter.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  chapter.startDay.isValid, chapter.endDay.map({ $0.isValid && $0 >= chapter.startDay }) ?? true,
                  chapter.pathIDs.isSubset(of: Set(paths.map(\.id))),
                  Set(chapter.photoIDs).count == chapter.photoIDs.count,
                  chapter.createdAt.timeIntervalSinceReferenceDate.isFinite,
                  chapter.updatedAt.timeIntervalSinceReferenceDate.isFinite, chapter.updatedAt >= chapter.createdAt else { throw LifeError.invalidValue }
            for memory in chapter.memories {
                guard memory.day.isValid, !memory.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw LifeError.invalidValue }
            }
        }
    }
}
extension LifeStore {
    public func saveChapter(_ chapter: LifeChapter, at date: Date = Date()) throws {
        var clean = chapter
        clean.title = clean.title.trimmingCharacters(in: .whitespacesAndNewlines)
        clean.updatedAt = max(clean.createdAt, date)
        try transaction { state in
            if let index = state.chapters.firstIndex(where: { $0.id == clean.id }) {
                guard clean.createdAt == state.chapters[index].createdAt else { throw LifeError.invalidValue }
                state.chapters[index] = clean
            } else { state.chapters.append(clean) }
        }
    }
    public func deleteChapter(id: UUID) throws {
        try transaction { state in
            guard state.chapters.contains(where: { $0.id == id }) else { throw LifeError.invalidValue }
            state.chapters.removeAll { $0.id == id }
        }
    }
}

@MainActor public protocol ChapterPhotoRepository {
    func save(_ data: Data) throws -> UUID
    func load(_ id: UUID) throws -> Data?
    func discardNewPhoto(_ id: UUID) throws
    /// Call only after successfully persisting the referencing state. Includes archived chapters.
    func removeUnreferenced(keeping ids: Set<UUID>) throws
}

/// UUID-only filenames, bounded files, atomic writes and iOS complete file protection.
/// Missing photos never make the JSON store unreadable. A crash between file and JSON
/// writes leaves an unreferenced file, cleaned after a successful load or mutation.
@MainActor public final class FileChapterPhotoRepository: ChapterPhotoRepository {
    public let directory: URL
    public init(directory: URL) { self.directory = directory }
    private func url(_ id: UUID) -> URL { directory.appendingPathComponent(id.uuidString + ".jpg") }
    public func save(_ data: Data) throws -> UUID {
        guard !data.isEmpty, data.count <= 12 * 1024 * 1024 else { throw LifeError.invalidValue }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let id = UUID()
        #if os(iOS)
        try data.write(to: url(id), options: [.atomic, .completeFileProtection])
        #else
        try data.write(to: url(id), options: .atomic)
        #endif
        return id
    }
    public func load(_ id: UUID) throws -> Data? {
        let file = url(id)
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        let values = try file.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey])
        guard values.isRegularFile == true, values.isSymbolicLink != true,
              let size = values.fileSize, size <= 12 * 1024 * 1024 else { throw LifeError.corruptStore }
        return try Data(contentsOf: file)
    }
    public func discardNewPhoto(_ id: UUID) throws {
        if FileManager.default.fileExists(atPath: url(id).path) { try FileManager.default.removeItem(at: url(id)) }
    }
    public func removeUnreferenced(keeping ids: Set<UUID>) throws {
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        for file in try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isRegularFileKey]) {
            guard file.pathExtension == "jpg", let id = UUID(uuidString: file.deletingPathExtension().lastPathComponent),
                  !ids.contains(id), try file.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else { continue }
            try FileManager.default.removeItem(at: file)
        }
    }
}

extension LifeStore {
    public func importChapterPhoto(_ data: Data, chapterID: UUID, photos: any ChapterPhotoRepository) throws {
        guard var chapter = state.chapters.first(where: { $0.id == chapterID }) else { throw LifeError.invalidValue }
        let id = try photos.save(data)
        chapter.photoIDs.append(id)
        do { try saveChapter(chapter) }
        catch {
            // Remove only this uncommitted new file. Never sweep against stale state
            // after an external JSON replacement or other failed save.
            try photos.discardNewPhoto(id)
            throw error
        }
    }
}

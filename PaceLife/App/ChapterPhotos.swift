import Foundation
import UIKit
import ImageIO
import PaceLifeCore

/// Decoding through ImageIO caps the rendered dimensions and re-encoding removes
/// original GPS/EXIF metadata. No library-wide photo permission is requested.
enum ChapterPhotoDecoder {
    static func jpeg(_ data: Data) throws -> Data {
        guard data.count <= 30 * 1024 * 1024,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 1600,
                kCGImageSourceCreateThumbnailWithTransform: true
              ] as CFDictionary),
              let jpeg = UIImage(cgImage: image).jpegData(compressionQuality: 0.85) else { throw LifeError.invalidValue }
        return jpeg
    }
}

extension AppModel {
    func saveChapter(_ chapter: LifeChapter) -> Bool {
        let saved = perform { try $0.saveChapter(chapter) }
        if saved { cleanChapterPhotos() }
        return saved
    }
    func deleteChapter(_ id: UUID) -> Bool {
        let saved = perform { try $0.deleteChapter(id: id) }
        if saved { cleanChapterPhotos() }
        return saved
    }
    func cleanChapterPhotos() {
        guard loaded, !saveFailed else { return }
        do { try photos.removeUnreferenced(keeping: state.referencedPhotoIDs); photoFailed = false }
        catch { photoFailed = true }
    }
    func importChapterPhoto(_ data: Data, chapterID: UUID) {
        do {
            let jpeg = try ChapterPhotoDecoder.jpeg(data)
            let saved = perform { try $0.importChapterPhoto(jpeg, chapterID: chapterID, photos: photos) }
            if saved { cleanChapterPhotos() } else { photoFailed = true }
        } catch { photoFailed = true }
    }

    func chapterPhoto(_ id: UUID) -> UIImage? {
        do {
            guard let data = try photos.load(id) else { return nil }
            return UIImage(data: data)
        } catch { return nil } // The view explicitly displays an unavailable-photo state.
    }
    func date(for day: DayKey) -> Date {
        let components = day.rawValue.split(separator: "-").compactMap { Int($0) }
        guard components.count == 3 else { return today }
        return Calendar.current.date(from: DateComponents(year: components[0], month: components[1], day: components[2], hour: 12)) ?? today
    }
}

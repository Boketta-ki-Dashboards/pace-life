import PaceLifeCore

enum ChapterCopy {
    case deleteMemory, newChapter, noChapters, privateNote, start, end, ongoing, photos, addPhotos, missingPhoto, photoError, retryCleanup, memories, addMemory, milestone, deleteChapter, deleteWarning, removePhoto, archive, restore
    case personal, education, work, health, travel, relationships
    func text(_ language: AppLanguage) -> String {
        let v: (String, String, String)
        switch self {
        case .deleteMemory: v = ("Erinnerung löschen", "Delete memory", "Удалить воспоминание")
        case .newChapter: v = ("Neues Kapitel", "New chapter", "Новая глава")
        case .noChapters: v = ("Bewahre Lebensabschnitte und persönliche Meilensteine auf.", "Keep life chapters and personal milestones.", "Сохраняй периоды жизни и личные достижения.")
        case .privateNote: v = ("Privat · nur auf diesem Gerät", "Private · on this device only", "Личное · только на этом устройстве")
        case .start: v = ("Beginn", "Start", "Начало")
        case .end: v = ("Ende", "End", "Конец")
        case .ongoing: v = ("Andauernd", "Ongoing", "Продолжается")
        case .photos: v = ("Fotos", "Photos", "Фотографии")
        case .addPhotos: v = ("Fotos auswählen", "Choose photos", "Выбрать фотографии")
        case .missingPhoto: v = ("Foto nicht verfügbar", "Photo unavailable", "Фото недоступно")
        case .photoError: v = ("Foto konnte nicht verarbeitet werden. Bitte erneut versuchen. Gespeicherte Einträge bleiben erhalten.", "Could not process the photo. Please try again. Saved entries are preserved.", "Не удалось обработать фото. Повтори попытку. Сохранённые записи не изменены.")
        case .retryCleanup: v = ("Fotodateien prüfen", "Check photo files", "Проверить файлы фотографий")
        case .memories: v = ("Erinnerungen", "Memories", "Воспоминания")
        case .addMemory: v = ("Erinnerung hinzufügen", "Add memory", "Добавить воспоминание")
        case .milestone: v = ("Persönlicher Meilenstein", "Personal milestone", "Личное достижение")
        case .deleteChapter: v = ("Kapitel löschen", "Delete chapter", "Удалить главу")
        case .deleteWarning: v = ("Dieses Kapitel, seine Erinnerungen und nicht mehr verwendete Fotos werden dauerhaft gelöscht. Life Paths bleiben erhalten.", "This chapter, its memories and unused photos will be permanently deleted. Life Paths are preserved.", "Глава, её воспоминания и неиспользуемые фотографии будут удалены навсегда. Life Paths сохранятся.")
        case .removePhoto: v = ("Foto entfernen", "Remove photo", "Удалить фото")
        case .archive: v = ("Archiv", "Archive", "Архив")
        case .restore: v = ("Wiederherstellen", "Restore", "Восстановить")
        case .personal: v = ("Persönlich", "Personal", "Личное")
        case .education: v = ("Bildung", "Education", "Образование")
        case .work: v = ("Beruf", "Work", "Работа")
        case .health: v = ("Gesundheit", "Health", "Здоровье")
        case .travel: v = ("Reisen", "Travel", "Путешествия")
        case .relationships: v = ("Beziehungen", "Relationships", "Отношения")
        }
        switch language { case .de: return v.0; case .en: return v.1; case .ru: return v.2 }
    }
}
extension AppModel {
    func chapterText(_ key: ChapterCopy) -> String { key.text(state.settings.language) }
    func categoryName(_ category: ChapterCategory) -> String {
        switch category {
        case .personal: chapterText(.personal); case .education: chapterText(.education)
        case .work: chapterText(.work); case .health: chapterText(.health)
        case .travel: chapterText(.travel); case .relationships: chapterText(.relationships)
        }
    }
}

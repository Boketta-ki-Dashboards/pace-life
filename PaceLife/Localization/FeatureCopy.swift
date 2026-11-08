import Foundation
import PaceLifeCore

/// Copy for reminders, recurring modes and backup (schema 10).
enum FeatureCopy {
    case reminders, reminder, addReminder, editReminder, time, enabled, reminderBody, remindersEmpty, remindersDetail
    case notificationsDenied, openSettings, reminderLimit, reminderNote, deleteReminder
    case priority, priorityNote, autoSchedule, autoScheduleNote, manualOnly, scheduledOn, scheduleRule
    case backup, backupDetail, exportData, exportNote, importData, importNote, restoreTitle, restoreMessage, restoreConfirm
    case restoreDone, restoreFailed, exportFailed, safetyCopy, backupContents

    func text(_ language: AppLanguage) -> String {
        let v: (String, String, String)
        switch self {
        case .reminders: v = ("Erinnerungen", "Reminders", "Напоминания")
        case .reminder: v = ("Erinnerung", "Reminder", "Напоминание")
        case .addReminder: v = ("Erinnerung hinzufügen", "Add reminder", "Добавить напоминание")
        case .editReminder: v = ("Erinnerung bearbeiten", "Edit reminder", "Изменить напоминание")
        case .time: v = ("Uhrzeit", "Time", "Время")
        case .enabled: v = ("Aktiv", "Active", "Включено")
        case .reminderBody: v = ("Pace Life erinnert dich an dein Vorhaben.", "Pace Life reminds you of your plan.", "Pace Life напоминает о твоём плане.")
        case .remindersEmpty: v = ("Noch keine Erinnerungen. Lege sie bei einer Gewohnheit oder Routine an.", "No reminders yet. Add them on a habit or routine.", "Пока нет напоминаний. Добавь их у привычки или рутины.")
        case .remindersDetail: v = ("Lokale Mitteilungen für Gewohnheiten und Routinen", "Local notifications for habits and routines", "Локальные уведомления для привычек и рутин")
        case .notificationsDenied: v = ("Mitteilungen sind für Pace Life in den iOS-Einstellungen ausgeschaltet. Die Erinnerung ist gespeichert, wird aber erst nach Erlaubnis zugestellt.", "Notifications are turned off for Pace Life in iOS Settings. The reminder is saved but only delivered once allowed.", "Уведомления для Pace Life отключены в настройках iOS. Напоминание сохранено, но придёт только после разрешения.")
        case .openSettings: v = ("iOS-Einstellungen öffnen", "Open iOS Settings", "Открыть настройки iOS")
        case .reminderLimit: v = ("iOS erlaubt höchstens 64 geplante Mitteilungen. Reduziere Wochentage oder andere Erinnerungen.", "iOS allows at most 64 scheduled notifications. Reduce weekdays or other reminders.", "iOS допускает не более 64 запланированных уведомлений. Сократи дни или другие напоминания.")
        case .reminderNote: v = ("Erinnerungen bleiben lokal. Die Erlaubnis wird erst beim ersten Aktivieren abgefragt. Archivierte Gewohnheiten und Routinen erinnern nicht mehr.", "Reminders stay local. Permission is only requested when you first enable one. Archived habits and routines no longer remind.", "Напоминания остаются на устройстве. Разрешение запрашивается только при первом включении. Архивные привычки и рутины больше не напоминают.")
        case .deleteReminder: v = ("Erinnerung löschen", "Delete reminder", "Удалить напоминание")
        case .priority: v = ("Tagespriorität", "Daily priority", "Приоритет дня")
        case .priorityNote: v = ("Mit dem Stern markierst du bis zu drei Tagesprioritäten. Sie stehen auf Heute oben und sind in Pace Adaptive vorab geschützt.", "Use the star to mark up to three daily priorities. They appear first on Today and are pre-protected in Pace Adaptive.", "Звёздочкой отметь до трёх приоритетов дня. Они показываются первыми и заранее защищены в Pace Adaptive.")
        case .autoSchedule: v = ("Automatisch aktivieren", "Activate automatically", "Включать автоматически")
        case .autoScheduleNote: v = ("An gewählten Wochentagen startet dieser Mode automatisch. Eine manuelle Auswahl gilt für den restlichen Tag. Bei Überschneidungen gewinnt der obere Mode in der Liste.", "On the selected weekdays this mode starts automatically. A manual choice applies for the rest of the day. If schedules overlap, the mode higher in the list wins.", "В выбранные дни режим включается автоматически. Ручной выбор действует до конца дня. При пересечении выигрывает режим выше в списке.")
        case .manualOnly: v = ("Nur manuell", "Manual only", "Только вручную")
        case .scheduledOn: v = ("Automatisch: %@", "Automatic: %@", "Автоматически: %@")
        case .scheduleRule: v = ("Wochenplan: Geplante Modes starten automatisch. Deine manuelle Wahl gilt für heute; ohne Plan bleibt sie aktiv. Frühere Tage behalten ihren gespeicherten Plan.", "Weekly plan: scheduled modes start automatically. Your manual choice applies today; without a plan it stays active. Earlier days keep their saved plan.", "Недельный план: запланированные режимы включаются сами. Ручной выбор действует сегодня; без плана он остаётся активным. Прошлые дни сохраняют свой план.")
        case .backup: v = ("Daten & Backup", "Data & backup", "Данные и резервная копия")
        case .backupDetail: v = ("Export, Wiederherstellung, Datenschutz", "Export, restore, privacy", "Экспорт, восстановление, конфиденциальность")
        case .exportData: v = ("Daten exportieren", "Export data", "Экспортировать данные")
        case .exportNote: v = ("Erstellt eine JSON-Datei mit Gewohnheiten, Verlauf, Modes, Routinen, Paths, Experiments, Chapters, Circles und Einstellungen. Fotos bleiben als separate Dateien auf diesem Gerät und sind nicht enthalten. Bewahre die Datei privat auf.", "Creates a JSON file with habits, history, modes, routines, paths, experiments, chapters, circles and settings. Photos stay as separate files on this device and are not included. Keep the file private.", "Создаёт JSON-файл с привычками, историей, режимами, рутинами, путями, экспериментами, главами, кругами и настройками. Фото остаются отдельными файлами на устройстве и не входят в файл. Храни его приватно.")
        case .importData: v = ("Backup wiederherstellen", "Restore backup", "Восстановить резервную копию")
        case .importNote: v = ("Eine Pace-Life-Backupdatei ersetzt nach Bestätigung alle aktuellen Daten. Vorher wird automatisch eine Sicherheitskopie des aktuellen Stands auf diesem Gerät abgelegt.", "A Pace Life backup file replaces all current data after confirmation. A safety copy of the current state is stored on this device first.", "Файл резервной копии Pace Life после подтверждения заменит все текущие данные. Перед этим на устройстве сохраняется копия текущего состояния.")
        case .restoreTitle: v = ("Alle Daten ersetzen?", "Replace all data?", "Заменить все данные?")
        case .restoreMessage: v = ("Das Backup enthält %@. Deine aktuellen Daten werden ersetzt; eine Sicherheitskopie bleibt auf dem Gerät.", "The backup contains %@. Your current data will be replaced; a safety copy stays on the device.", "Резервная копия содержит: %@. Текущие данные будут заменены; копия останется на устройстве.")
        case .restoreConfirm: v = ("Ersetzen", "Replace", "Заменить")
        case .restoreDone: v = ("Backup wiederhergestellt.", "Backup restored.", "Резервная копия восстановлена.")
        case .restoreFailed: v = ("Die Datei ist kein gültiges Pace-Life-Backup oder stammt aus einer neueren Version. Es wurde nichts verändert.", "The file is not a valid Pace Life backup or comes from a newer version. Nothing was changed.", "Файл не является корректной резервной копией Pace Life или создан более новой версией. Ничего не изменено.")
        case .exportFailed: v = ("Der Export konnte nicht erstellt werden. Deine Daten sind unverändert.", "The export could not be created. Your data is unchanged.", "Не удалось создать экспорт. Данные не изменены.")
        case .safetyCopy: v = ("Sicherheitskopie gespeichert", "Safety copy saved", "Копия сохранена")
        case .backupContents: v = ("%@ Gewohnheiten, %@ Einträge, %@ Paths, %@ Chapters", "%@ habits, %@ entries, %@ paths, %@ chapters", "привычек: %@, записей: %@, путей: %@, глав: %@")
        }
        switch language { case .de: return v.0; case .en: return v.1; case .ru: return v.2 }
    }
}

extension AppModel {
    func feature(_ key: FeatureCopy) -> String { key.text(state.settings.language) }
    func feature(_ key: FeatureCopy, _ values: String...) -> String {
        var result = key.text(state.settings.language)
        for value in values {
            guard let range = result.range(of: "%@") else { break }
            result.replaceSubrange(range, with: value)
        }
        return result
    }
}

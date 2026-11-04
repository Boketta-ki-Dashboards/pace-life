import PaceLifeCore

enum PathCopy {
    case source, routineRule, paths, newPath, editPath, milestones, addMilestone, linkedHabit, manual, category, targetDate, noPaths, contributionRule, status, active, paused, completed, archived, finish, resume, todayValue, startDate, completedDate
    func text(_ language: AppLanguage) -> String {
        let v: (String, String, String)
        switch self {
        case .source: v = ("Beitragsquelle", "Contribution source", "Источник вклада")
        case .routineRule: v = ("Routinen zählen vollständig erledigte gespeicherte Sessions ab dem Path-Start. Eine Session zählt einmal; Teilfortschritt und geplante Minuten werden nicht als erledigte Arbeit gebucht. Korrekturen aktualisieren den Beitrag auch nach Archivierung.", "Routines count fully completed stored sessions from the path start. Each session counts once; partial progress and planned minutes are not recorded as completed work. Corrections update the contribution even after archiving.", "Рутины учитывают полностью выполненные сохранённые сессии с начала пути. Каждая сессия считается один раз; частичный прогресс и запланированные минуты не считаются выполненной работой. Исправления обновляют вклад и после архивации.")
        case .paths: v = ("Life Paths", "Life Paths", "Life Paths")
        case .newPath: v = ("Neuer Life Path", "New Life Path", "Новый Life Path")
        case .editPath: v = ("Life Path bearbeiten", "Edit Life Path", "Изменить Life Path")
        case .milestones: v = ("Meilensteine", "Milestones", "Этапы")
        case .addMilestone: v = ("Meilenstein hinzufügen", "Add milestone", "Добавить этап")
        case .linkedHabit: v = ("Beitrag aus Gewohnheit", "Habit contribution", "Вклад привычки")
        case .manual: v = ("Manuell erfassen", "Record manually", "Ввести вручную")
        case .category: v = ("Lebensbereich", "Life area", "Сфера жизни")
        case .targetDate: v = ("Zieldatum", "Target date", "Целевая дата")
        case .noPaths: v = ("Verbinde ein langfristiges Ziel mit deinen täglichen Handlungen.", "Connect a long-term goal with your daily actions.", "Свяжи долгосрочную цель с ежедневными действиями.")
        case .contributionRule: v = ("Verknüpfte Meilensteine zählen tatsächliche Habit-Werte ab dem Startdatum in derselben Einheit, auch nach Archivierung. Korrekturen ersetzen den bisherigen Beitrag. Quelle und Einheit bleiben nach dem Anlegen fest; Minuten werden nicht automatisch in Stunden umgerechnet.", "Linked milestones count actual habit values from the start date in the same unit, including archived habits. Corrections replace the previous contribution. Source and unit stay fixed after creation; minutes are not automatically converted to hours.", "Связанные этапы учитывают фактические значения привычки с даты начала в той же единице, включая архивные привычки. Исправление заменяет прежний вклад. Источник и единица фиксируются при создании; минуты не переводятся автоматически в часы.")
        case .status: v = ("Status", "Status", "Статус")
        case .active: v = ("Aktiv", "Active", "Активен")
        case .paused: v = ("Pausiert", "Paused", "Приостановлен")
        case .completed: v = ("Abgeschlossen", "Completed", "Завершён")
        case .archived: v = ("Archiviert", "Archived", "В архиве")
        case .finish: v = ("Path abschließen", "Complete path", "Завершить путь")
        case .resume: v = ("Aktivieren", "Activate", "Активировать")
        case .todayValue: v = ("Heutiger Beitrag", "Today's contribution", "Сегодняшний вклад")
        case .startDate: v = ("Startdatum", "Start date", "Дата начала")
        case .completedDate: v = ("Abgeschlossen am", "Completed on", "Дата завершения")
        }
        switch language { case .de: return v.0; case .en: return v.1; case .ru: return v.2 }
    }
}
extension AppModel {
    func pathText(_ key: PathCopy) -> String { key.text(state.settings.language) }
    func pathStatusName(_ status: PathStatus) -> String {
        switch status { case .active: pathText(.active); case .paused: pathText(.paused); case .completed: pathText(.completed); case .archived: pathText(.archived) }
    }
}

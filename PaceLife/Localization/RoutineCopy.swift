import PaceLifeCore

enum RoutineCopy {
    case routines, newRoutine, editRoutine, notes, steps, stepTitle, addStep, stepDuration
    case plannedTime, mode, noMode, noRoutines, start, pause, resume, history, snapshotNote, archiveNote
    func text(_ language: AppLanguage) -> String {
        let v: (String, String, String)
        switch self {
        case .routines: v = ("Routinen", "Routines", "Рутины")
        case .newRoutine: v = ("Neue Routine", "New routine", "Новая рутина")
        case .editRoutine: v = ("Routine bearbeiten", "Edit routine", "Изменить рутину")
        case .notes: v = ("Beschreibung", "Description", "Описание")
        case .steps: v = ("Schritte", "Steps", "Шаги")
        case .stepTitle: v = ("Schritttitel", "Step title", "Название шага")
        case .addStep: v = ("Schritt hinzufügen", "Add step", "Добавить шаг")
        case .stepDuration: v = ("Dauer planen", "Plan duration", "Запланировать длительность")
        case .plannedTime: v = ("Geplante Tageszeit", "Planned time", "Запланированное время")
        case .mode: v = ("Life Mode", "Life Mode", "Life Mode")
        case .noMode: v = ("In jedem Modus", "In every mode", "В любом режиме")
        case .noRoutines: v = ("Keine Routinen für diese Ansicht. Verwalte deine Routinen und ihre Planung.", "No routines for this view. Manage your routines and their schedule.", "В этом разделе нет рутин. Настрой рутины и их расписание.")
        case .start: v = ("Routine starten", "Start routine", "Начать рутину")
        case .pause: v = ("Unterbrechen", "Pause", "Приостановить")
        case .resume: v = ("Fortsetzen", "Resume", "Продолжить")
        case .history: v = ("Tagesverlauf", "Daily history", "История по дням")
        case .snapshotNote: v = ("Die gestartete Routine behält ihre ursprünglichen Schritte. Änderungen der Vorlage gelten für den nächsten Start an einem neuen Tag.", "A started routine keeps its original steps. Template edits apply when starting on a new day.", "Начатая рутина сохраняет исходные шаги. Изменения шаблона применяются при запуске в новый день.")
        case .archiveNote: v = ("Archivierte Routinen bleiben mit ihrem Tagesverlauf erhalten.", "Archived routines keep their daily history.", "Архивные рутины сохраняют историю по дням.")
        }
        switch language { case .de: return v.0; case .en: return v.1; case .ru: return v.2 }
    }
}
extension AppModel {
    func routineText(_ key: RoutineCopy) -> String { key.text(state.settings.language) }
}

import Foundation
import PaceLifeCore

/// All product copy is explicitly translated; user-authored names are never translated.
enum Copy: CaseIterable {
    case today, development, circles, profile, localOnly, welcome, welcomeDetail
    case dayChanged, validNumber, notScheduled
    case habits, newHabit, editHabit, name, goal, binary, count, duration, target, minutes, frequency, everyDay
    case save, cancel, done, edit, archive, archiveMessage, confirmArchive, add, noHabits, noDueHabits, manageHabits
    case progress, progressDetail, completed, recordProgress, actualValue, reset, originalGoal, emptyProgress
    case modes, newMode, editMode, noMode, activeMode, activate, deactivate, selectedHabits, emptyMode, deleteMode, deleteModeMessage
    case widgets, widgetsHelp, noWidgets, theme, language, automatic, light, dark, privacy, privacyDetail
    case unavailable, futureDetail, circlesDetail, connectDetail, placeholder, errorTitle, saveError, loadError, retry
    case history, noHistory, historyNote, habitScheduleNote, modeNote, renameNote, streak, scheduledDays
    case pathsDetail, adaptiveDetail, chaptersDetail, experimentsDetail, about, version, durationHelp, archiveHelp

    func text(_ language: AppLanguage) -> String {
        let values: (String, String, String)
        switch self {
        case .dayChanged: values = ("Ein neuer Tag hat begonnen. Schließe diesen Eintrag und öffne ihn erneut für heute.", "A new day has started. Close this entry and reopen it for today.", "Начался новый день. Закрой запись и открой её снова для сегодняшнего дня.")
        case .validNumber: values = ("Gib eine gültige Zahl ein. Zähler benötigen ganze Zahlen; Ziele müssen größer als null sein.", "Enter a valid number. Counts need whole numbers; targets must be greater than zero.", "Введи корректное число. Количество должно быть целым, а цель — больше нуля.")
        case .notScheduled: values = ("Diese Gewohnheit ist heute nicht geplant.", "This habit is not scheduled today.", "Эта привычка не запланирована на сегодня.")
        case .today: values = ("Heute", "Today", "Сегодня")
        case .development: values = ("Entwicklung", "Growth", "Развитие")
        case .circles: values = ("Kreise", "Circles", "Круги")
        case .profile: values = ("Profil", "Profile", "Профиль")
        case .localOnly: values = ("Nur auf diesem Gerät", "Only on this device", "Только на этом устройстве")
        case .welcome: values = ("Dein Tag. Dein Tempo.", "Your day. Your pace.", "Твой день. Твой темп.")
        case .welcomeDetail: values = ("Beginne mit einer kleinen Gewohnheit. Du bestimmst, was heute zählt.", "Start with a small habit. You decide what matters today.", "Начни с небольшой привычки. Ты решаешь, что важно сегодня.")
        case .habits: values = ("Gewohnheiten", "Habits", "Привычки")
        case .newHabit: values = ("Gewohnheit erstellen", "Create habit", "Создать привычку")
        case .editHabit: values = ("Gewohnheit bearbeiten", "Edit habit", "Изменить привычку")
        case .name: values = ("Name", "Name", "Название")
        case .goal: values = ("Zieltyp", "Goal type", "Тип цели")
        case .binary: values = ("Abhaken", "Check off", "Отметка")
        case .count: values = ("Anzahl", "Count", "Количество")
        case .duration: values = ("Dauer", "Duration", "Длительность")
        case .target: values = ("Tagesziel", "Daily target", "Цель на день")
        case .minutes: values = ("Minuten", "Minutes", "Минуты")
        case .frequency: values = ("Wochentage", "Days of the week", "Дни недели")
        case .everyDay: values = ("Täglich", "Every day", "Каждый день")
        case .save: values = ("Speichern", "Save", "Сохранить")
        case .cancel: values = ("Abbrechen", "Cancel", "Отмена")
        case .done: values = ("Fertig", "Done", "Готово")
        case .edit: values = ("Bearbeiten", "Edit", "Изменить")
        case .archive: values = ("Archivieren", "Archive", "В архив")
        case .archiveMessage: values = ("Die Gewohnheit wird ausgeblendet. Ihre bisherigen Einträge bleiben erhalten.", "The habit will be hidden. Its previous entries will be kept.", "Привычка будет скрыта. Предыдущие записи сохранятся.")
        case .confirmArchive: values = ("Gewohnheit archivieren?", "Archive habit?", "Переместить привычку в архив?")
        case .add: values = ("Hinzufügen", "Add", "Добавить")
        case .noHabits: values = ("Noch keine Gewohnheiten", "No habits yet", "Пока нет привычек")
        case .noDueHabits: values = ("Heute ist Raum für dich", "Room for yourself today", "Сегодня есть время для себя")
        case .manageHabits: values = ("Alle Gewohnheiten", "All habits", "Все привычки")
        case .progress: values = ("Dein Tagesfortschritt", "Your daily progress", "Прогресс за день")
        case .progressDetail: values = ("Jeder kleine Schritt zählt.", "Every small step counts.", "Каждый маленький шаг важен.")
        case .completed: values = ("Erledigt", "Completed", "Выполнено")
        case .recordProgress: values = ("Fortschritt eintragen", "Record progress", "Записать результат")
        case .actualValue: values = ("Heute erreicht", "Achieved today", "Достигнуто сегодня")
        case .reset: values = ("Zurücksetzen", "Reset", "Сбросить")
        case .originalGoal: values = ("Gespeichertes Tagesziel", "Saved daily target", "Сохранённая цель дня")
        case .emptyProgress: values = ("Für heute sind keine Gewohnheiten geplant. Du kannst deine Wochentage oder deinen Life Mode anpassen.", "No habits are scheduled for today. You can adjust your weekdays or Life Mode.", "На сегодня нет привычек. Можно изменить дни недели или Life Mode.")
        case .modes: values = ("Life Modes", "Life Modes", "Life Modes")
        case .newMode: values = ("Life Mode erstellen", "Create Life Mode", "Создать Life Mode")
        case .editMode: values = ("Life Mode bearbeiten", "Edit Life Mode", "Изменить Life Mode")
        case .noMode: values = ("Alle Gewohnheiten", "All habits", "Все привычки")
        case .activeMode: values = ("Dein Life Mode", "Your Life Mode", "Твой Life Mode")
        case .activate: values = ("Aktivieren", "Activate", "Активировать")
        case .deactivate: values = ("Modus beenden", "End mode", "Завершить режим")
        case .selectedHabits: values = ("Gewohnheiten in diesem Modus", "Habits in this mode", "Привычки в этом режиме")
        case .emptyMode: values = ("Wähle die Gewohnheiten für diesen Modus. Ohne Auswahl ist der Modus ein Ruhetag.", "Choose habits for this mode. An empty selection makes this a rest day.", "Выбери привычки для режима. Без выбранных привычек это день отдыха.")
        case .deleteMode: values = ("Life Mode löschen", "Delete Life Mode", "Удалить Life Mode")
        case .deleteModeMessage: values = ("Der Modus wird gelöscht. Frühere Habit-Einträge bleiben unverändert.", "The mode will be deleted. Previous habit entries stay unchanged.", "Режим будет удалён. Предыдущие записи привычек не изменятся.")
        case .widgets: values = ("Home gestalten", "Customize home", "Настроить главный экран")
        case .widgetsHelp: values = ("Blende Karten ein oder aus. Ziehe sie am Griff in deine gewünschte Reihenfolge.", "Show or hide cards. Drag their handles to put them in your preferred order.", "Показывай или скрывай карточки. Перетаскивай их за ручки, чтобы изменить порядок.")
        case .noWidgets: values = ("Dein Home ist frei", "Your home is clear", "Главный экран пуст")
        case .theme: values = ("Darstellung", "Appearance", "Оформление")
        case .language: values = ("Sprache", "Language", "Язык")
        case .automatic: values = ("Automatisch", "Automatic", "Автоматически")
        case .light: values = ("Hell", "Light", "Светлое")
        case .dark: values = ("Dunkel", "Dark", "Тёмное")
        case .privacy: values = ("Privat von Anfang an", "Private from the start", "Приватность с самого начала")
        case .privacyDetail: values = ("Deine Eingaben bleiben lokal in Pace Life. Es gibt kein Konto, keine Synchronisierung und keine Datenfreigabe an andere Pace-Apps. Geräte-Backups unterliegen deinen iOS-Einstellungen.", "Your entries stay locally in Pace Life. There is no account, synchronization or data sharing with other Pace apps. Device backups follow your iOS settings.", "Записи хранятся локально в Pace Life. Нет аккаунта, синхронизации и передачи данных другим приложениям Pace. Резервные копии устройства зависят от настроек iOS.")
        case .unavailable: values = ("Noch nicht verfügbar", "Not available yet", "Пока недоступно")
        case .futureDetail: values = ("Dieser Bereich ist geplant. Deine heutigen Gewohnheiten funktionieren bereits lokal.", "This area is planned. Your daily habits already work locally.", "Этот раздел запланирован. Ежедневные привычки уже работают локально.")
        case .circlesDetail: values = ("Gemeinsame Ziele brauchen sichere Einladungen und ausdrückliche Freigaben. Pace Circles folgt in einer späteren Phase.", "Shared goals need secure invitations and explicit sharing. Pace Circles will arrive in a later phase.", "Общие цели требуют безопасных приглашений и явного согласия. Pace Circles появится позже.")
        case .connectDetail: values = ("Eine Verbindung zu anderen Pace-Apps wird erst nach Freigabe der Schnittstellen möglich. Es ist kein Konto verbunden.", "Connections to other Pace apps require approved interfaces. No account is connected.", "Связь с другими приложениями Pace появится после согласования интерфейсов. Аккаунт не подключён.")
        case .placeholder: values = ("Logo-Platzhalter", "Logo placeholder", "Временный логотип")
        case .errorTitle: values = ("Speichern nicht möglich", "Could not save", "Не удалось сохранить")
        case .saveError: values = ("Die Änderung wurde nicht gespeichert. Deine bisherigen Daten bleiben erhalten. Bitte versuche es erneut.", "The change was not saved. Your existing data is preserved. Please try again.", "Изменение не сохранено. Предыдущие данные сохранены. Попробуй снова.")
        case .loadError: values = ("Die lokalen Daten konnten nicht geöffnet werden. Sie wurden nicht überschrieben. Prüfe den verfügbaren Gerätespeicher und versuche es erneut.", "Local data could not be opened. It has not been overwritten. Check available device storage and try again.", "Не удалось открыть локальные данные. Они не перезаписаны. Проверь свободное место и попробуй снова.")
        case .retry: values = ("Erneut versuchen", "Try again", "Попробовать снова")
        case .history: values = ("Verlauf", "History", "История")
        case .noHistory: values = ("Noch keine Einträge", "No entries yet", "Пока нет записей")
        case .historyNote: values = ("Einträge behalten ihr ursprüngliches Tagesziel, auch wenn du die Gewohnheit oder den Life Mode später änderst.", "Entries keep their original daily target, even if you later change the habit or Life Mode.", "Записи сохраняют исходную цель дня, даже если привычка или Life Mode изменятся.")
        case .habitScheduleNote: values = ("Mindestens ein Wochentag. Ein aktiver Life Mode kann die heutige Auswahl zusätzlich einschränken.", "Choose at least one weekday. An active Life Mode can further limit today's selection.", "Выбери хотя бы один день. Активный Life Mode может дополнительно ограничить выбор на сегодня.")
        case .modeNote: values = ("Ein Life Mode verändert nur deine heutige Auswahl, niemals frühere Einträge. Geplante Wochentage gelten weiterhin.", "A Life Mode changes today's selection, never previous entries. Scheduled weekdays still apply.", "Life Mode меняет сегодняшний выбор, но не прошлые записи. Дни недели продолжают учитываться.")
        case .renameNote: values = ("Änderungen am Ziel gelten für neue Tageseinträge. Bereits gespeicherte Tagesziele bleiben erhalten.", "Goal changes apply to new daily entries. Previously saved daily targets are preserved.", "Изменения цели применяются к новым записям. Ранее сохранённые цели дня сохраняются.")
        case .streak: values = ("Serie", "Streak", "Серия")
        case .scheduledDays: values = ("Geplante Tage", "Scheduled days", "Запланированные дни")
        case .pathsDetail: values = ("Langfristige Ziele mit Etappen und echten Fortschritten.", "Long-term goals with milestones and meaningful progress.", "Долгосрочные цели с этапами и реальным прогрессом.")
        case .adaptiveDetail: values = ("Tagespläne passend zu Zeit und Energie – immer mit deiner Zustimmung.", "Daily plans that fit your time and energy, always with your consent.", "Планы с учётом времени и энергии — всегда с твоего согласия.")
        case .chaptersDetail: values = ("Deine private Chronik mit Erinnerungen und Lebensabschnitten.", "Your private journal of memories and life chapters.", "Личная хроника воспоминаний и этапов жизни.")
        case .experimentsDetail: values = ("Neue Gewohnheiten bewusst ausprobieren und ehrlich auswerten.", "Try new habits intentionally and reflect on the results.", "Осознанно пробуй новые привычки и оценивай результаты.")
        case .about: values = ("Über Pace Life", "About Pace Life", "О Pace Life")
        case .version: values = ("Erstes lokales Inkrement", "First local increment", "Первый локальный этап")
        case .durationHelp: values = ("Dauer wird in Minuten erfasst. Ein Timer ist noch nicht enthalten.", "Duration is recorded in minutes. A timer is not included yet.", "Длительность указывается в минутах. Таймер пока не предусмотрен.")
        case .archiveHelp: values = ("Archivierte Gewohnheiten bleiben mit ihrem Verlauf erhalten.", "Archived habits and their history are retained.", "Привычки в архиве и их история сохраняются.")
        }
        switch language { case .de: return values.0; case .en: return values.1; case .ru: return values.2 }
    }
}

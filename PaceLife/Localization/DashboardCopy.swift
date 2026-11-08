import Foundation
import PaceLifeCore

/// Copy of the Pace dashboard, statistics, profile and navigation. `%@` placeholders
/// receive already localized numbers so digits follow the selected app language.
enum DashboardCopy {
    case greetingNamed, customize, addWidget, editHint, chooseSize, sizeCompact, sizeRegular, sizeLarge
    case moveUp, moveDown, removeWidget, noHiddenWidgets, widgetLibrary
    case todayHabits, ofHabits, remaining, goalReached, adjustDay, focusMinutes, routinesToday, noPlanToday
    case streakDays, streakOpen, streakDone, streakRest, record, streakRule
    case yourWeek, weekTotal, weekAverage, daysReached, calendarTitle, monthReached, goalLegend, noPlanKnown, forecastDay
    case statistics, day, thisWeek, thisMonth, today, vsPrevious, tapDay, bestValues, bestDay, bestWeek, longestStreak, perDay, noValues
    case overview, active, paths, habitsDone, noRoutinesToday, nextUp, startRoutine
    case yourName, nameHint, yourActivity, settings, appearanceLanguage, wordmarkNote, data, homeLayout, homeLayoutDetail
    case connectStatus, connectAvailable, connectPlanned, connectNoAccount, connectIdentity, connectFriends, connectGroups, connectProgress, connectRule
    case yourCirclesWidget, noCirclesWidget, activeExperiments, noExperimentsWidget, latestChapter, noChaptersWidget, checkedInToday, openCheckIn
    case growthPaths, growthStats, growthChapters, growthExperiments, growthAdaptive, privacyShort, modesDetail, habitsDetail

    func text(_ language: AppLanguage) -> String {
        let v: (String, String, String)
        switch self {
        case .greetingNamed: v = ("Hi %@", "Hi %@", "Привет, %@")
        case .customize: v = ("Anpassen", "Customize", "Настроить")
        case .addWidget: v = ("Widget hinzufügen", "Add widget", "Добавить виджет")
        case .editHint: v = ("Halten und verschieben, um deine Übersicht anzupassen.", "Hold and drag to arrange your overview.", "Удерживай и перетаскивай, чтобы настроить обзор.")
        case .chooseSize: v = ("Größe auswählen", "Choose size", "Выбрать размер")
        case .sizeCompact: v = ("Klein", "Small", "Маленький")
        case .sizeRegular: v = ("Mittel", "Medium", "Средний")
        case .sizeLarge: v = ("Groß", "Large", "Большой")
        case .moveUp: v = ("Nach oben", "Move up", "Выше")
        case .moveDown: v = ("Nach unten", "Move down", "Ниже")
        case .removeWidget: v = ("Entfernen", "Remove", "Убрать")
        case .noHiddenWidgets: v = ("Alle Widgets sind bereits auf deiner Übersicht.", "All widgets are already on your overview.", "Все виджеты уже на главном экране.")
        case .widgetLibrary: v = ("Wähle ein Widget für deine Übersicht. Alle Inhalte stammen aus deinen gespeicherten Daten.", "Choose a widget for your overview. All content comes from your saved data.", "Выбери виджет для обзора. Все данные берутся из твоих сохранённых записей.")
        case .todayHabits: v = ("Deine Gewohnheiten heute", "Your habits today", "Твои привычки сегодня")
        case .ofHabits: v = ("von %@ Gewohnheiten", "of %@ habits", "из %@ привычек")
        case .remaining: v = ("Noch %@ bis zu deinem Tagesziel", "%@ left to reach your daily goal", "Осталось %@ до цели дня")
        case .goalReached: v = ("Tagesziel erreicht", "Daily goal reached", "Цель дня достигнута")
        case .adjustDay: v = ("Tag anpassen", "Adjust day", "Настроить день")
        case .focusMinutes: v = ("Minuten erfasst", "minutes logged", "минут записано")
        case .routinesToday: v = ("Routinen heute", "routines today", "рутин сегодня")
        case .noPlanToday: v = ("Heute ist nichts geplant – Raum für dich.", "Nothing is planned today – room for yourself.", "Сегодня ничего не запланировано – время для себя.")
        case .streakDays: v = ("%@ Tage", "%@ days", "%@ дн.")
        case .streakOpen: v = ("Heute offen", "Open today", "Сегодня ещё открыто")
        case .streakDone: v = ("Heute geschafft", "Done today", "Сегодня выполнено")
        case .streakRest: v = ("Heute Ruhetag", "Rest day today", "Сегодня день отдыха")
        case .record: v = ("Rekord: %@", "Best: %@", "Рекорд: %@")
        case .streakRule: v = ("Eine Serie zählt Tage, an denen alle geplanten Gewohnheiten erledigt wurden. Ruhetage unterbrechen sie nicht. Sie beginnt mit dem ersten gespeicherten Tagesplan; frühere Tage werden nicht rekonstruiert.", "A streak counts days on which every planned habit was completed. Rest days do not break it. It starts with the first saved daily plan; earlier days are not reconstructed.", "Серия считает дни, когда выполнены все запланированные привычки. Дни отдыха её не прерывают. Она начинается с первого сохранённого плана дня; более ранние дни не восстанавливаются.")
        case .yourWeek: v = ("Deine Woche", "Your week", "Твоя неделя")
        case .weekTotal: v = ("Erledigt gesamt", "Completed in total", "Всего выполнено")
        case .weekAverage: v = ("Ø Tagesfortschritt", "Ø daily progress", "Ø прогресс за день")
        case .daysReached: v = ("%@ von %@ Tagen Ziel erreicht", "Goal reached on %@ of %@ days", "Цель достигнута в %@ из %@ дн.")
        case .calendarTitle: v = ("Kalender", "Calendar", "Календарь")
        case .monthReached: v = ("%@ von %@ Tagen erreicht", "%@ of %@ days reached", "Достигнуто %@ из %@ дн.")
        case .goalLegend: v = ("Tagesziel erreicht", "Daily goal reached", "Цель дня достигнута")
        case .noPlanKnown: v = ("Für diesen Tag ist kein Tagesplan gespeichert. Gespeicherte Ergebnisse werden angezeigt, fehlende gelten nicht als verpasst.", "No daily plan is stored for this day. Saved results are shown; missing ones are not treated as missed.", "Для этого дня план не сохранён. Показаны сохранённые результаты; отсутствующие не считаются пропущенными.")
        case .forecastDay: v = ("Vorschau mit deinem aktuellen Plan", "Preview with your current plan", "Предпросмотр по текущему плану")
        case .statistics: v = ("Statistik", "Statistics", "Статистика")
        case .day: v = ("Tag", "Day", "День")
        case .thisWeek: v = ("Diese Woche", "This week", "Эта неделя")
        case .thisMonth: v = ("Dieser Monat", "This month", "Этот месяц")
        case .today: v = ("Heute", "Today", "Сегодня")
        case .vsPrevious: v = ("%@ ggü. Vorperiode (Ø pro Tag)", "%@ vs. previous period (Ø per day)", "%@ к прошлому периоду (Ø в день)")
        case .tapDay: v = ("Tippe auf einen Tag für Details.", "Tap a day for details.", "Нажми на день, чтобы увидеть детали.")
        case .bestValues: v = ("Deine Bestwerte", "Your best values", "Твои рекорды")
        case .bestDay: v = ("Bester Tag (12 Monate)", "Best day (12 months)", "Лучший день (12 месяцев)")
        case .bestWeek: v = ("Beste Woche (12 Monate)", "Best week (12 months)", "Лучшая неделя (12 месяцев)")
        case .longestStreak: v = ("Längste Serie", "Longest streak", "Самая длинная серия")
        case .perDay: v = ("Ø %@ pro Tag", "Ø %@ per day", "Ø %@ в день")
        case .noValues: v = ("Noch keine Werte in diesem Zeitraum.", "No values in this period yet.", "За этот период пока нет значений.")
        case .overview: v = ("Übersicht", "Overview", "Обзор")
        case .active: v = ("aktiv", "active", "активен")
        case .paths: v = ("Paths", "Paths", "Пути")
        case .habitsDone: v = ("erledigt", "completed", "выполнено")
        case .noRoutinesToday: v = ("Heute sind keine Routinen geplant.", "No routines are planned today.", "Сегодня рутины не запланированы.")
        case .nextUp: v = ("Nächster Meilenstein", "Next milestone", "Следующий этап")
        case .startRoutine: v = ("Starten", "Start", "Начать")
        case .yourName: v = ("Dein Name", "Your name", "Твоё имя")
        case .nameHint: v = ("Nur für die Begrüßung auf diesem Gerät. Wird nicht geteilt.", "Only used for the greeting on this device. Never shared.", "Используется только для приветствия на этом устройстве. Никуда не передаётся.")
        case .yourActivity: v = ("Deine Aktivität", "Your activity", "Твоя активность")
        case .settings: v = ("Einstellungen", "Settings", "Настройки")
        case .appearanceLanguage: v = ("Darstellung & Sprache", "Appearance & language", "Оформление и язык")
        case .wordmarkNote: v = ("Die Wortmarke „pace life“ ist eine Annäherung in Systemschrift. Das originale Logo-Asset wird nachgereicht.", "The “pace life” wordmark is a system-font approximation. The original logo asset will follow.", "Логотип «pace life» набран системным шрифтом. Оригинальный логотип будет добавлен позже.")
        case .data: v = ("Daten & Datenschutz", "Data & privacy", "Данные и конфиденциальность")
        case .homeLayout: v = ("Home gestalten", "Customize home", "Настроить главный экран")
        case .homeLayoutDetail: v = ("Widgets, Reihenfolge, Größe", "Widgets, order, size", "Виджеты, порядок, размер")
        case .connectStatus: v = ("Nicht verbunden", "Not connected", "Не подключено")
        case .connectAvailable: v = ("Heute verfügbar", "Available today", "Доступно сейчас")
        case .connectPlanned: v = ("Geplant nach Freigabe", "Planned after approval", "Запланировано после согласования")
        case .connectNoAccount: v = ("Pace Life arbeitet vollständig lokal. Es gibt kein Konto und keine Verbindung zu Pace Social oder anderen Pace-Apps.", "Pace Life works fully locally. There is no account and no connection to Pace Social or other Pace apps.", "Pace Life работает полностью локально. Нет аккаунта и связи с Pace Social или другими приложениями Pace.")
        case .connectIdentity: v = ("Gemeinsame Pace-Identität", "Shared Pace identity", "Общая учётная запись Pace")
        case .connectFriends: v = ("Freunde aus Pace Social", "Friends from Pace Social", "Друзья из Pace Social")
        case .connectGroups: v = ("Echte Gruppen und Challenges", "Real groups and challenges", "Настоящие группы и челленджи")
        case .connectProgress: v = ("Appübergreifende Fortschritte", "Cross-app progress", "Прогресс между приложениями")
        case .connectRule: v = ("Eine Verbindung entsteht erst nach einem freigegebenen Schnittstellenvertrag, mit ausdrücklicher Zustimmung und widerruflich. Private Daten werden niemals automatisch geteilt.", "A connection only becomes possible after an approved interface contract, with explicit and revocable consent. Private data is never shared automatically.", "Подключение станет возможным только после утверждённого контракта интерфейса, с явным и отзываемым согласием. Личные данные никогда не передаются автоматически.")
        case .yourCirclesWidget: v = ("Deine Kreise", "Your circles", "Твои круги")
        case .noCirclesWidget: v = ("Erstelle im Tab Kreise einen lokalen Circle.", "Create a local circle in the Circles tab.", "Создай локальный круг во вкладке «Круги».")
        case .activeExperiments: v = ("Aktive Experimente", "Active experiments", "Активные эксперименты")
        case .noExperimentsWidget: v = ("Kein Experiment läuft gerade.", "No experiment is running.", "Сейчас нет активных экспериментов.")
        case .latestChapter: v = ("Life Chapters", "Life Chapters", "Life Chapters")
        case .noChaptersWidget: v = ("Halte wichtige Lebensabschnitte privat fest.", "Capture important life chapters privately.", "Сохраняй важные этапы жизни приватно.")
        case .checkedInToday: v = ("Heute erfasst", "Checked in today", "Сегодня отмечено")
        case .openCheckIn: v = ("Heute noch offen", "Still open today", "Сегодня ещё не отмечено")
        case .growthPaths: v = ("Langfristige Ziele und Meilensteine", "Long-term goals and milestones", "Долгосрочные цели и этапы")
        case .growthStats: v = ("Woche, Monat und Bestwerte", "Week, month and best values", "Неделя, месяц и рекорды")
        case .growthChapters: v = ("Private Chronik mit Fotos", "Private timeline with photos", "Личная хроника с фото")
        case .growthExperiments: v = ("Ausprobieren, messen, reflektieren", "Try, measure, reflect", "Пробуй, измеряй, анализируй")
        case .growthAdaptive: v = ("Tagesplan an Zeit und Energie anpassen", "Fit today's plan to your time and energy", "Подстрой план дня под время и энергию")
        case .privacyShort: v = ("Lokal, ohne Konto, ohne Synchronisierung", "Local, no account, no sync", "Локально, без аккаунта и синхронизации")
        case .modesDetail: v = ("Alltagsmodi und ihre Gewohnheiten", "Everyday modes and their habits", "Режимы дня и их привычки")
        case .habitsDetail: v = ("Alle Gewohnheiten und Archiv", "All habits and archive", "Все привычки и архив")
        }
        switch language { case .de: return v.0; case .en: return v.1; case .ru: return v.2 }
    }
}

extension AppModel {
    func dash(_ key: DashboardCopy) -> String { key.text(state.settings.language) }
    /// Fills `%@` placeholders in order with already localized values.
    func dash(_ key: DashboardCopy, _ values: String...) -> String {
        var result = key.text(state.settings.language)
        for value in values {
            guard let range = result.range(of: "%@") else { break }
            result.replaceSubrange(range, with: value)
        }
        return result
    }
}

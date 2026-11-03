import PaceLifeCore

enum CalendarCopy {
    case calendar, week, month, forecast, unknownHistory, planned, recorded, noRecords, previous, next
    func text(_ language: AppLanguage) -> String {
        let v: (String, String, String)
        switch self {
        case .calendar: v = ("Kalender & Verlauf", "Calendar & history", "Календарь и история")
        case .week: v = ("Woche", "Week", "Неделя")
        case .month: v = ("Monat", "Month", "Месяц")
        case .forecast: v = ("Vorschau mit den aktuellen Wiederholungen und dem aktiven Life Mode. Spätere Änderungen können diesen Plan ändern.", "Preview using current schedules and the active Life Mode. Later edits may change this plan.", "Предварительный план по текущему расписанию и активному Life Mode. Последующие изменения могут его изменить.")
        case .unknownHistory: v = ("Für frühere Tage werden gespeicherte Ergebnisse angezeigt. Der damalige vollständige Tagesplan ist nicht bekannt; fehlende Einträge gelten nicht automatisch als verpasst.", "Past days show saved results. The complete historical plan is unknown; missing records are not automatically treated as missed activities.", "Для прошлых дней показаны сохранённые результаты. Полный план того дня неизвестен; отсутствие записи не означает пропуск.")
        case .planned: v = ("Geplant", "Planned", "Запланировано")
        case .recorded: v = ("Gespeicherte Ergebnisse", "Saved results", "Сохранённые результаты")
        case .noRecords: v = ("Keine gespeicherten Ergebnisse für diesen Tag.", "No saved results for this day.", "За этот день нет сохранённых результатов.")
        case .previous: v = ("Zurückblättern", "Previous period", "Предыдущий период")
        case .next: v = ("Weiterblättern", "Next period", "Следующий период")
        }
        switch language { case .de: return v.0; case .en: return v.1; case .ru: return v.2 }
    }
}
extension AppModel {
    func calendarText(_ key: CalendarCopy) -> String { key.text(state.settings.language) }
}

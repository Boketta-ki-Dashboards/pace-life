import PaceLifeCore

enum AdaptiveCopy {
    case available, energy, load, protect, propose, accept, decline, undo, adjusted, suggested, current, routineTime, unknown, overBudget, rule, frozen, deferred, original, actual, noActivities
    func text(_ language: AppLanguage) -> String {
        let v: (String, String, String)
        switch self {
        case .available: v = ("Zeitbudget heute (Minuten)", "Today's time budget (minutes)", "Время на сегодня (минуты)")
        case .energy: v = ("Energie (1 niedrig, 5 hoch)", "Energy (1 low, 5 high)", "Энергия (1 низкая, 5 высокая)")
        case .load: v = ("Belastung (1 niedrig, 5 hoch)", "Load (1 low, 5 high)", "Нагрузка (1 низкая, 5 высокая)")
        case .protect: v = ("Ziele unverändert lassen", "Keep goals unchanged", "Не менять цели")
        case .propose: v = ("Tagesplan vorschlagen", "Suggest daily plan", "Предложить план дня")
        case .accept: v = ("Annehmen", "Accept", "Принять")
        case .decline: v = ("Ablehnen", "Decline", "Отклонить")
        case .undo: v = ("Anpassung zurücknehmen", "Undo adjustment", "Отменить изменение")
        case .adjusted: v = ("Bestätigtes Tagesziel", "Accepted daily goal", "Принятая цель дня")
        case .suggested: v = ("Vorgeschlagene Minuten", "Suggested minutes", "Предложенные минуты")
        case .current: v = ("Aktuell geplante Minuten", "Currently planned minutes", "Запланированные минуты")
        case .routineTime: v = ("Davon feste Routinen", "Including fixed routines", "Включая фиксированные рутины")
        case .unknown: v = ("Aktivitäten/Schritte ohne Zeitangabe", "Activities/steps without a duration", "Действия/шаги без длительности")
        case .overBudget: v = ("Der aktuelle Plan überschreitet dein Zeitbudget. Abgelehnte Vorschläge und feste Aufgaben behalten ihren ursprünglichen Umfang.", "The current plan exceeds your time budget. Declined suggestions and fixed activities keep their original scope.", "Текущий план превышает доступное время. Отклонённые предложения и фиксированные задачи сохраняют исходный объём.")
        case .rule: v = ("Nur Minuten-Ziele werden reduziert. Routinen und geschützte Ziele bleiben fest. Energie unter 3 oder Belastung über 3 reduziert das verfügbare Planungsbudget proportional. Aktive Life Paths erhalten bei der Verteilung doppeltes Gewicht. Zeitangaben fehlen für manche Aktivitäten; diese sind nicht im Minutenbudget enthalten.", "Only minute goals are reduced. Routines and protected goals stay fixed. Energy below 3 or load above 3 proportionally lowers the planning budget. Active Life Paths receive double weight in allocation. Activities without a duration are not included in the minute budget.", "Сокращаются только цели в минутах. Рутины и защищённые цели не меняются. Энергия ниже 3 или нагрузка выше 3 пропорционально уменьшает время планирования. Активные Life Paths получают двойной вес при распределении. Действия без длительности не входят в расчёт времени.")
        case .frozen: v = ("Der Plan hält die heutigen Ausgangsziele fest. Jede Anpassung braucht deine Zustimmung. Du kannst sie bearbeiten oder zurücknehmen; neue Aktivitäten und Mode-Wechsel ändern diesen Plan nicht automatisch.", "This plan freezes today's original goals. Each adjustment needs your consent. You can edit or undo it; new activities and mode changes do not automatically change this plan.", "План фиксирует исходные цели дня. Каждое изменение требует согласия. Его можно изменить или отменить; новые действия и смена режима не меняют этот план автоматически.")
        case .deferred: v = ("Heute zurückgestellt · zählt nicht als erledigt", "Deferred today · does not count as complete", "Отложено на сегодня · не считается выполненным")
        case .original: v = ("Ursprüngliches Ziel", "Original goal", "Исходная цель")
        case .actual: v = ("Tatsächlich erreicht", "Actually achieved", "Фактически выполнено")
        case .noActivities: v = ("Keine heutigen Minuten-Ziele. Lege eine Dauer-Gewohnheit an oder prüfe deinen Life Mode.", "No minute goals today. Create a duration habit or check your Life Mode.", "На сегодня нет целей в минутах. Создай привычку с длительностью или проверь Life Mode.")
        }
        switch language { case .de: return v.0; case .en: return v.1; case .ru: return v.2 }
    }
}
extension AppModel {
    func adaptiveText(_ key: AdaptiveCopy) -> String { key.text(state.settings.language) }
}

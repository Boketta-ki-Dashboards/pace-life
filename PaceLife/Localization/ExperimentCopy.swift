import Foundation
import PaceLifeCore

enum ExperimentCopy {
    case newExperiment, noExperiments, question, context, metrics, addMetric, unit, baseline, checkIn, missing, mean, last, change, observations, finish, repeatExperiment, reflection, custom, days, scaleMin, scaleMax, number, rating, dataRule, noData, recorded, deleteMetric
    func text(_ language: AppLanguage) -> String {
        let v: (String, String, String)
        switch self {
        case .newExperiment: v = ("Neues Experiment", "New experiment", "Новый эксперимент")
        case .noExperiments: v = ("Beobachte deinen Alltag mit selbst gewählten Messgrößen.", "Observe your daily life with your own measures.", "Наблюдай за своей жизнью с помощью собственных показателей.")
        case .question: v = ("Fragestellung und Ziel", "Question and goal", "Вопрос и цель")
        case .context: v = ("Ausgangssituation", "Starting situation", "Исходная ситуация")
        case .metrics: v = ("Messgrößen", "Measures", "Показатели")
        case .addMetric: v = ("Messgröße hinzufügen", "Add measure", "Добавить показатель")
        case .unit: v = ("Einheit", "Unit", "Единица")
        case .baseline: v = ("Ausgangswert (optional)", "Baseline (optional)", "Исходное значение (необязательно)")
        case .checkIn: v = ("Check-in erfassen", "Record check-in", "Записать наблюдение")
        case .missing: v = ("Fehlende Tage", "Missing days", "Дни без данных")
        case .mean: v = ("Mittelwert der erfassten Werte", "Mean of recorded values", "Среднее записанных значений")
        case .last: v = ("Letzter erfasster Wert", "Last recorded value", "Последнее записанное значение")
        case .change: v = ("Veränderung zum Ausgangswert", "Change from baseline", "Изменение от исходного значения")
        case .observations: v = ("Diese Werte beschreiben deine Beobachtungen. Sie belegen keine Ursache und keine gesundheitliche Wirkung.", "These values describe your observations. They do not establish a cause or a health effect.", "Эти значения описывают наблюдения. Они не доказывают причину или влияние на здоровье.")
        case .finish: v = ("Experiment abschließen", "Complete experiment", "Завершить эксперимент")
        case .repeatExperiment: v = ("Als neues Experiment wiederholen", "Repeat as a new experiment", "Повторить как новый эксперимент")
        case .reflection: v = ("Reflexion", "Reflection", "Выводы")
        case .custom: v = ("Eigener Zeitraum", "Custom period", "Свой период")
        case .days: v = ("Tage", "Days", "Дни")
        case .scaleMin: v = ("Skala von", "Scale from", "Шкала от")
        case .scaleMax: v = ("Skala bis", "Scale to", "Шкала до")
        case .number: v = ("Numerischer Wert", "Numeric value", "Числовое значение")
        case .rating: v = ("Selbsteinschätzung", "Self-rating", "Самооценка")
        case .dataRule: v = ("Leere Felder bleiben fehlende Daten. Ja/Nein: 1/0. Dauer: Minuten. Messgrößen und Ausgangswerte bleiben nach dem Anlegen unverändert.", "Empty fields remain missing data. Yes/no: 1/0. Duration: minutes. Measures and baselines stay fixed after creation.", "Пустые поля остаются без данных. Да/нет: 1/0. Длительность: минуты. Показатели и исходные значения фиксируются при создании.")
        case .noData: v = ("Noch keine Messwerte", "No measurements yet", "Измерений пока нет")
        case .recorded: v = ("Tage mit Messwerten", "Days with measurements", "Дни с измерениями")
        case .deleteMetric: v = ("Messgröße entfernen", "Remove measure", "Удалить показатель")
        }
        switch language { case .de: return v.0; case .en: return v.1; case .ru: return v.2 }
    }
}
extension AppModel {
    func experimentText(_ key: ExperimentCopy) -> String { key.text(state.settings.language) }
    func metricKindName(_ kind: ExperimentMetricKind) -> String {
        switch kind { case .number: experimentText(.number); case .duration: text(.duration); case .rating: experimentText(.rating); case .binary: text(.binary) }
    }
    func metricUnit(_ metric: ExperimentMetric) -> String {
        switch metric.kind {
        case .duration: text(.minutes)
        case .binary: "0 / 1"
        case .rating: number(metric.scaleMinimum) + "–" + number(metric.scaleMaximum)
        case .number: metric.unit
        }
    }
    func parseMeasurement(_ text: String) -> Double? {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("-") { return parseNumber(String(clean.dropFirst())).map { -$0 } }
        return parseNumber(clean)
    }
    func saveExperiment(_ experiment: LifeExperiment) -> Bool { perform { try $0.saveExperiment(experiment) } }
    func recordExperiment(_ id: UUID, day: DayKey, values: [ExperimentValue], notes: String) -> Bool {
        perform { try $0.recordExperiment(id: id, day: day, values: values, notes: notes) }
    }
}

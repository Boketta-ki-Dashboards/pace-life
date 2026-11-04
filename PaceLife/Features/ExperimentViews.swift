import SwiftUI
import Charts
import PaceLifeCore

struct ExperimentsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var creating = false
    var body: some View {
        NavigationStack {
            List {
                SaveErrorBanner()
                if model.state.experiments.isEmpty { Text(model.experimentText(.noExperiments)) }
                ForEach(ExperimentStatus.allCases, id: \.self) { status in
                    Section(model.pathStatusName(status == .active ? .active : status == .completed ? .completed : .archived)) {
                        ForEach(model.state.experiments.filter { $0.status == status }) { experiment in
                            NavigationLink { ExperimentDetail(experimentID: experiment.id) } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(experiment.title).font(.headline)
                                    Text(model.dayLabel(experiment.startDay) + " – " + model.dayLabel(experiment.endDay)).font(.caption)
                                }
                            }.accessibilityIdentifier("experiment.open." + experiment.title)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden).background(PaceColor.background)
            .navigationTitle("Life Experiments").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.done)) { dismiss() }.accessibilityIdentifier("closeExperiments") }
                ToolbarItem(placement: .primaryAction) {
                    Button { creating = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel(model.experimentText(.newExperiment)).accessibilityIdentifier("addExperiment")
                }
            }.sheet(isPresented: $creating) { ExperimentEditor() }
        }
    }
}

struct ExperimentDetail: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let experimentID: UUID
    @State private var editing = false
    @State private var recording = false
    private var experiment: LifeExperiment? { model.state.experiments.first { $0.id == experimentID } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SaveErrorBanner()
                if let experiment {
                    PaceCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(experiment.question).font(.headline)
                            Text(experiment.context)
                            Text(model.dayLabel(experiment.startDay) + " – " + model.dayLabel(experiment.endDay))
                            let count = model.state.experimentCheckIns.filter { $0.experimentID == experiment.id && !$0.values.isEmpty }.count
                            ProgressView(value: Double(count), total: Double(experiment.plannedDays)).tint(PaceColor.accent)
                            Text("\(count) / \(experiment.plannedDays) · " + model.experimentText(.recorded)).font(.footnote)
                            ForEach(model.state.habits.filter { experiment.habitIDs.contains($0.id) }) { habit in
                                NavigationLink { HabitDetailContent(habitID: habit.id) } label: { Label(habit.title, systemImage: "link") }
                            }
                        }
                    }
                    if experiment.status != .archived && experiment.startDay <= DayKey(date: model.today) {
                        Button(model.experimentText(.checkIn)) { recording = true }.buttonStyle(PaceButtonStyle()).accessibilityIdentifier("experimentCheckIn")
                    }
                    ForEach(experiment.metrics) { metric in metricCard(metric, in: experiment) }
                    PaceCard { Text(model.experimentText(.observations)).font(.footnote) }
                    if !experiment.reflection.isEmpty { Text(experiment.reflection) }
                    Button(model.text(.edit)) { editing = true }.buttonStyle(PaceButtonStyle(kind: .secondary))
                    if experiment.status == .active {
                        Button(model.experimentText(.finish)) { model.perform { try $0.finishExperiment(id: experimentID) } }
                            .disabled(experiment.startDay > DayKey(date: model.today)).accessibilityIdentifier("finishExperiment")
                    }
                    if experiment.status != .archived {
                        Button(model.text(.archive)) { model.perform { try $0.archiveExperiment(id: experimentID) } }
                    }
                    Button(model.experimentText(.repeatExperiment)) {
                        if model.perform({ _ = try $0.repeatExperiment(id: experimentID) }) { dismiss() }
                    }.buttonStyle(PaceButtonStyle(kind: .secondary)).accessibilityIdentifier("repeatExperiment")
                }
            }.padding(16)
        }.background(PaceColor.background)
            .navigationTitle(experiment?.title ?? "Life Experiments").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $editing) { if let experiment { ExperimentEditor(existing: experiment) } }
            .sheet(isPresented: $recording) { if let experiment { ExperimentCheckInEditor(experiment: experiment) } }
    }
    private func metricCard(_ metric: ExperimentMetric, in experiment: LifeExperiment) -> some View {
        let summary = model.state.experimentSummary(experiment, metric: metric, through: DayKey(date: model.today))
        return PaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(metric.title + " · " + model.metricUnit(metric)).font(.headline)
                if summary.samples.isEmpty { Text(model.experimentText(.noData)) }
                else {
                    // Discrete points never bridge or interpolate missing days.
                    Chart(summary.samples) { sample in
                        PointMark(x: .value(model.experimentText(.days), experiment.startDay.distance(to: sample.day) + 1), y: .value(metric.title, sample.value))
                            .foregroundStyle(PaceColor.accent)
                    }
                    .chartXScale(domain: 1...max(2, experiment.plannedDays))
                    .chartXAxisLabel(model.experimentText(.days)).chartYAxisLabel(model.metricUnit(metric))
                    .frame(height: 180).accessibilityLabel(metric.title)
                    ForEach(summary.samples) { sample in
                        LabeledContent(model.dayLabel(sample.day), value: model.number(sample.value))
                            .font(.footnote).accessibilityIdentifier("experiment.value." + metric.title + "." + sample.day.rawValue)
                    }
                }
                LabeledContent(model.experimentText(.missing), value: "\(summary.missingDays)")
                if let mean = summary.mean { LabeledContent(model.experimentText(.mean), value: model.number(mean)) }
                if let baseline = summary.baseline { LabeledContent(model.experimentText(.baseline), value: model.number(baseline)) }
                if let last = summary.lastValue { LabeledContent(model.experimentText(.last), value: model.number(last)) }
                if let change = summary.changeFromBaseline { LabeledContent(model.experimentText(.change), value: model.number(change)) }
            }
        }
    }
}

private struct ExperimentMetricDraft: Identifiable {
    let id = UUID()
    var title = ""
    var kind = ExperimentMetricKind.number
    var unit = ""
    var minimum = 1
    var maximum = 10
    var baseline = ""
}
struct ExperimentEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let existing: LifeExperiment?
    @State private var title = ""
    @State private var question = ""
    @State private var context = ""
    @State private var reflection = ""
    @State private var start = Date()
    @State private var end = Date()
    @State private var duration = 14
    @State private var metrics = [ExperimentMetricDraft()]
    @State private var habitIDs: Set<UUID> = []
    @State private var initialized = false
    init(existing: LifeExperiment? = nil) { self.existing = existing }
    private var builtMetrics: [ExperimentMetric]? {
        if let existing { return existing.metrics }
        var result: [ExperimentMetric] = []
        for draft in metrics {
            guard !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            let baseline = draft.baseline.isEmpty ? nil : model.parseMeasurement(draft.baseline)
            if !draft.baseline.isEmpty && baseline == nil { return nil }
            let metric = ExperimentMetric(id: draft.id, title: draft.title, kind: draft.kind, unit: draft.unit,
                                          scaleMinimum: Double(draft.minimum), scaleMaximum: Double(draft.maximum), baseline: baseline)
            if let baseline, !metric.accepts(baseline) { return nil }
            result.append(metric)
        }
        return result.isEmpty ? nil : result
    }
    var body: some View {
        NavigationStack {
            Form {
                SaveErrorBanner()
                Section {
                    TextField(model.text(.name), text: $title).accessibilityIdentifier("experimentTitle")
                    TextField(model.experimentText(.question), text: $question, axis: .vertical)
                    TextField(model.experimentText(.context), text: $context, axis: .vertical)
                    if existing == nil {
                        DatePicker(model.chapterText(.start), selection: $start, displayedComponents: .date)
                        Picker(model.experimentText(.days), selection: $duration) {
                            ForEach([7, 14, 30], id: \.self) { Text("\($0)").tag($0) }
                            Text(model.experimentText(.custom)).tag(0)
                        }.onChange(of: duration) { _, _ in updateEnd() }
                        .onChange(of: start) { _, _ in updateEnd() }
                    }
                    DatePicker(model.chapterText(.end), selection: $end, in: start..., displayedComponents: .date)
                        .disabled(existing == nil && duration != 0)
                    TextField(model.experimentText(.reflection), text: $reflection, axis: .vertical)
                }
                if existing == nil { metricFields }
                Section(model.text(.habits)) {
                    ForEach(model.state.habits) { habit in
                        Toggle(habit.title, isOn: Binding(get: { habitIDs.contains(habit.id) }, set: {
                            if $0 { habitIDs.insert(habit.id) } else { habitIDs.remove(habit.id) }
                        }))
                    }
                }
                Text(model.experimentText(.dataRule)).font(.footnote)
            }
            .scrollContentBackground(.hidden).background(PaceColor.background)
            .navigationTitle("Life Experiments").navigationBarTitleDisplayMode(.inline)
            .onAppear {
                guard !initialized else { return }; initialized = true
                if let existing {
                    title = existing.title; question = existing.question; context = existing.context; reflection = existing.reflection
                    start = model.date(for: existing.startDay); end = model.date(for: existing.endDay); habitIDs = existing.habitIDs
                } else { updateEnd() }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.text(.save)) { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || builtMetrics == nil || DayKey(date: end) < DayKey(date: start))
                        .accessibilityIdentifier("saveExperiment")
                }
            }
        }
    }
    private var metricFields: some View {
        Section(model.experimentText(.metrics)) {
            ForEach($metrics) { $draft in
                VStack(alignment: .leading, spacing: 12) {
                    TextField(model.text(.name), text: $draft.title).accessibilityIdentifier("metricTitle")
                    Picker(model.experimentText(.metrics), selection: $draft.kind) {
                        ForEach(ExperimentMetricKind.allCases, id: \.self) { Text(model.metricKindName($0)).tag($0) }
                    }
                    if draft.kind == .number { TextField(model.experimentText(.unit), text: $draft.unit) }
                    if draft.kind == .rating {
                        Stepper(model.experimentText(.scaleMin) + " \(draft.minimum)", value: $draft.minimum, in: 0...(draft.maximum - 1))
                        Stepper(model.experimentText(.scaleMax) + " \(draft.maximum)", value: $draft.maximum, in: (draft.minimum + 1)...100)
                    }
                    TextField(model.experimentText(.baseline), text: $draft.baseline).keyboardType(.numbersAndPunctuation)
                    Button(model.experimentText(.deleteMetric), role: .destructive) { metrics.removeAll { $0.id == draft.id } }
                }
            }
            Button(model.experimentText(.addMetric)) { metrics.append(ExperimentMetricDraft()) }
        }
    }
    private func updateEnd() {
        if duration > 0 { end = Calendar.current.date(byAdding: .day, value: duration - 1, to: start) ?? start }
    }
    private func save() {
        guard let metrics = builtMetrics else { return }
        var experiment = existing ?? LifeExperiment(title: title, startDay: DayKey(date: start), endDay: DayKey(date: end), metrics: metrics)
        experiment.title = title; experiment.question = question; experiment.context = context
        experiment.endDay = DayKey(date: end); experiment.habitIDs = habitIDs; experiment.reflection = reflection
        if model.saveExperiment(experiment) { dismiss() }
    }
}

struct ExperimentCheckInEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let experiment: LifeExperiment
    @State private var date = Date()
    @State private var values: [UUID: String] = [:]
    @State private var notes = ""
    @State private var initialized = false
    private var last: Date { model.date(for: min(DayKey(date: model.today), experiment.endDay, experiment.completedDay ?? experiment.endDay)) }
    private var parsed: [ExperimentValue]? {
        var result: [ExperimentValue] = []
        for metric in experiment.metrics {
            let text = (values[metric.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty { continue }
            guard let value = model.parseMeasurement(text), metric.accepts(value) else { return nil }
            result.append(ExperimentValue(metricID: metric.id, value: value))
        }
        return result
    }
    var body: some View {
        NavigationStack {
            Form {
                SaveErrorBanner()
                DatePicker(model.experimentText(.days), selection: $date, in: model.date(for: experiment.startDay)...last, displayedComponents: .date)
                    .onChange(of: date) { _, _ in loadDay() }
                ForEach(experiment.metrics) { metric in
                    TextField(metric.title + " · " + model.metricUnit(metric), text: Binding(get: { values[metric.id] ?? "" }, set: { values[metric.id] = $0 }))
                        .keyboardType(.numbersAndPunctuation).accessibilityIdentifier("measurement." + metric.title)
                }
                TextField(model.routineText(.notes), text: $notes, axis: .vertical)
                Text(model.experimentText(.dataRule)).font(.footnote)
            }
            .navigationTitle(model.experimentText(.checkIn)).navigationBarTitleDisplayMode(.inline)
            .onAppear { if !initialized { initialized = true; date = last; loadDay() } }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.text(.save)) {
                        if let parsed, model.recordExperiment(experiment.id, day: DayKey(date: date), values: parsed, notes: notes) { dismiss() }
                    }.disabled(parsed == nil).accessibilityIdentifier("saveCheckIn")
                }
            }
        }
    }
    private func loadDay() {
        let old = model.state.experimentCheckIns.first { $0.experimentID == experiment.id && $0.day == DayKey(date: date) }
        values = Dictionary(uniqueKeysWithValues: (old?.values ?? []).map { ($0.metricID, model.inputNumber($0.value)) })
        notes = old?.notes ?? ""
    }
}

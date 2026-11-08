import SwiftUI
import Charts
import PaceLifeCore

struct ExperimentsView: View {
    @Environment(AppModel.self) private var model
    @State private var creating = false
    var body: some View {
        PaceSubpage(title: "Life Experiments", subtitle: model.text(.experimentsDetail)) {
            Button { creating = true } label: { PaceSquareIcon(systemImage: "plus") }
                .buttonStyle(.plain)
                .accessibilityLabel(model.experimentText(.newExperiment)).accessibilityIdentifier("addExperiment")
        } content: {
            if model.state.experiments.isEmpty {
                PaceCard {
                    PaceEmptyState(systemImage: "flask", title: "Life Experiments", message: model.experimentText(.noExperiments)) {
                        Button(model.experimentText(.newExperiment)) { creating = true }.buttonStyle(PaceButtonStyle(kind: .secondary))
                    }
                }
            }
            ForEach(ExperimentStatus.allCases, id: \.self) { status in
                let items = model.state.experiments.filter { $0.status == status }
                if !items.isEmpty {
                    PaceSectionTitle(model.pathStatusName(status == .active ? .active : status == .completed ? .completed : .archived))
                    ForEach(items) { experiment in
                        NavigationLink(value: AppRoute.experiment(experiment.id)) { ExperimentRowCard(experiment: experiment) }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("experiment.open." + experiment.title)
                    }
                }
            }
        }
        .sheet(isPresented: $creating) { ExperimentEditor() }
    }
}

struct ExperimentRowCard: View {
    @Environment(AppModel.self) private var model
    let experiment: LifeExperiment
    var body: some View {
        let count = model.state.experimentCheckIns.filter { $0.experimentID == experiment.id && !$0.values.isEmpty }.count
        let progress = experiment.plannedDays > 0 ? Double(count) / Double(experiment.plannedDays) : 0
        PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(experiment.title).font(.headline).foregroundStyle(PaceColor.textPrimary)
                        Text(model.dayLabel(experiment.startDay) + " – " + model.dayLabel(experiment.endDay))
                            .font(.footnote).foregroundStyle(PaceColor.textSecondary)
                    }
                    Spacer(minLength: PaceSpacing.xs)
                    Text(model.number(Double(count)) + "/" + model.number(Double(experiment.plannedDays)))
                        .font(.title3.weight(.heavy)).monospacedDigit()
                    PaceChevron()
                }
                PaceProgressBar(progress: progress)
                if model.experimentCheckedInToday(experiment) {
                    Label(model.experimentText(.recorded), systemImage: "checkmark.circle.fill").font(.footnote).foregroundStyle(PaceColor.accent)
                }
            }
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
        PaceSubpage(title: experiment?.title ?? "Life Experiments", subtitle: experiment.map { model.dayLabel($0.startDay) + " – " + model.dayLabel($0.endDay) }) {
            if experiment != nil {
                Button { editing = true } label: { PaceSquareIcon(systemImage: "pencil") }
                    .buttonStyle(.plain).accessibilityLabel(model.text(.edit)).accessibilityIdentifier("editExperiment")
            }
        } content: {
            if let experiment {
                let count = model.state.experimentCheckIns.filter { $0.experimentID == experiment.id && !$0.values.isEmpty }.count
                PaceCard {
                    VStack(alignment: .leading, spacing: PaceSpacing.s) {
                        HStack(alignment: .center, spacing: PaceSpacing.m) {
                            VStack(alignment: .leading, spacing: PaceSpacing.xxs) {
                                Text(model.experimentText(.recorded)).font(.headline)
                                Text(model.number(Double(count))).font(.system(size: 48, weight: .bold)).monospacedDigit()
                                Text(model.experimentDaysLabel(experiment.plannedDays)).font(.subheadline).foregroundStyle(PaceColor.textSecondary)
                            }
                            Spacer(minLength: PaceSpacing.xs)
                            PaceRing(progress: experiment.plannedDays > 0 ? Double(count) / Double(experiment.plannedDays) : 0, diameter: 92, lineWidth: 11,
                                     centerText: model.percent(experiment.plannedDays > 0 ? Double(count) / Double(experiment.plannedDays) : 0))
                        }
                        if !experiment.question.isEmpty { Text(experiment.question).font(.subheadline.weight(.semibold)) }
                        if !experiment.context.isEmpty { Text(experiment.context).font(.subheadline).foregroundStyle(PaceColor.textSecondary) }
                        ForEach(model.state.habits.filter { experiment.habitIDs.contains($0.id) }) { habit in
                            NavigationLink(value: AppRoute.habit(habit.id)) { Label(habit.title, systemImage: "link") }
                                .buttonStyle(PaceLinkButtonStyle())
                        }
                        if experiment.status != .archived && experiment.startDay <= DayKey(date: model.today) {
                            Button(model.experimentText(.checkIn)) { recording = true }
                                .buttonStyle(PaceButtonStyle()).accessibilityIdentifier("experimentCheckIn")
                        }
                    }
                }
                ForEach(experiment.metrics) { metric in metricCard(metric, in: experiment) }
                Label(model.experimentText(.observations), systemImage: "info.circle").font(.footnote).foregroundStyle(PaceColor.textSecondary)
                if !experiment.reflection.isEmpty {
                    PaceCard {
                        VStack(alignment: .leading, spacing: PaceSpacing.xs) {
                            Text(model.experimentText(.reflection)).font(.headline)
                            Text(experiment.reflection)
                        }
                    }
                }
                VStack(spacing: PaceSpacing.xs) {
                    if experiment.status == .active {
                        Button(model.experimentText(.finish)) { model.perform { try $0.finishExperiment(id: experimentID) } }
                            .buttonStyle(PaceButtonStyle(kind: .secondary))
                            .disabled(experiment.startDay > DayKey(date: model.today)).accessibilityIdentifier("finishExperiment")
                    }
                    Button(model.experimentText(.repeatExperiment)) {
                        if model.perform({ _ = try $0.repeatExperiment(id: experimentID) }) { dismiss() }
                    }.buttonStyle(PaceButtonStyle(kind: .secondary)).accessibilityIdentifier("repeatExperiment")
                    if experiment.status != .archived {
                        Button(model.text(.archive)) { model.perform { try $0.archiveExperiment(id: experimentID) } }
                            .buttonStyle(PaceButtonStyle(kind: .destructive))
                    }
                }
            }
        }
        .sheet(isPresented: $editing) { if let experiment { ExperimentEditor(existing: experiment) } }
        .sheet(isPresented: $recording) { if let experiment { ExperimentCheckInEditor(experiment: experiment) } }
    }
    private func metricCard(_ metric: ExperimentMetric, in experiment: LifeExperiment) -> some View {
        let summary = model.state.experimentSummary(experiment, metric: metric, through: DayKey(date: model.today))
        return PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                PaceCardHeader(title: metric.title, trailing: { Text(model.metricUnit(metric)).font(.footnote).foregroundStyle(PaceColor.textSecondary) })
                if summary.samples.isEmpty {
                    Text(model.experimentText(.noData)).foregroundStyle(PaceColor.textSecondary)
                } else {
                    // Discrete points never bridge or interpolate missing days.
                    Chart {
                        if let baseline = summary.baseline {
                            RuleMark(y: .value(model.experimentText(.baseline), baseline))
                                .foregroundStyle(PaceColor.textSecondary)
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        }
                        ForEach(summary.samples) { sample in
                            PointMark(x: .value(model.experimentText(.days), experiment.startDay.distance(to: sample.day) + 1), y: .value(metric.title, sample.value))
                                .foregroundStyle(PaceColor.accentStrong)
                                .symbolSize(70)
                        }
                    }
                    .chartXScale(domain: 1...max(2, experiment.plannedDays))
                    .chartXAxisLabel(model.experimentText(.days)).chartYAxisLabel(model.metricUnit(metric))
                    .frame(height: 180).accessibilityLabel(metric.title)
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: PaceSpacing.xs), GridItem(.flexible(), spacing: PaceSpacing.xs)], spacing: PaceSpacing.xs) {
                    PaceStatTile(value: model.number(Double(summary.missingDays)), label: model.experimentText(.missing))
                    if let mean = summary.mean { PaceStatTile(value: model.number(mean), label: model.experimentText(.mean)) }
                    if let baseline = summary.baseline { PaceStatTile(value: model.number(baseline), label: model.experimentText(.baseline)) }
                    if let last = summary.lastValue { PaceStatTile(value: model.number(last), label: model.experimentText(.last)) }
                    if let change = summary.changeFromBaseline { PaceStatTile(value: model.signedNumber(change), label: model.experimentText(.change)) }
                }
                ForEach(summary.samples.reversed()) { sample in
                    HStack {
                        Text(model.dayLabel(sample.day))
                        Spacer()
                        Text(model.number(sample.value)).monospacedDigit()
                    }
                    .font(.footnote).foregroundStyle(PaceColor.textSecondary)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("experiment.value." + metric.title + "." + sample.day.rawValue)
                }
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
            .paceFormStyle()
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

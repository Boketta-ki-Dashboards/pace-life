import SwiftUI
import PaceLifeCore

struct HabitEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let existing: Habit?
    @State private var title: String
    @State private var kind: GoalType
    @State private var targetText = ""
    @State private var initialized = false
    @State private var weekdays: Set<Int>

    init(existing: Habit? = nil) {
        self.existing = existing
        _title = State(initialValue: existing?.title ?? "")
        _kind = State(initialValue: existing?.goalType ?? .binary)
        _weekdays = State(initialValue: existing?.weekdays ?? Set(1...7))
    }

    private var target: Double? { kind == .binary ? 1 : model.parseNumber(targetText) }
    private var validTarget: Bool { guard let target else { return false }; return target > 0 && (kind != .count || target.rounded() == target) }
    private var valid: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !weekdays.isEmpty && validTarget }

    var body: some View {
        NavigationStack {
            Form {
                if model.saveFailed { Section { SaveErrorBanner() } }
                Section(model.text(.name)) {
                    TextField(model.text(.name), text: $title).textInputAutocapitalization(.sentences)
                        .accessibilityIdentifier("habitTitle")
                }
                Section {
                    PaceSegmentedControl(selection: $kind, options: GoalType.allCases.map { (value: $0, title: model.goalName($0)) })
                        .accessibilityElement(children: .contain)
                    if kind != .binary {
                        TextField(model.text(.target), text: $targetText)
                            .keyboardType(kind == .count ? .numberPad : .decimalPad).accessibilityIdentifier("habitTarget")
                        if !validTarget { Text(model.text(.validNumber)).font(.footnote).foregroundStyle(PaceColor.danger) }
                        if kind == .duration { Text(model.text(.durationHelp)).font(.footnote).foregroundStyle(PaceColor.textSecondary) }
                    }
                } footer: { Text(model.text(.renameNote)) }
                Section {
                    PaceWeekdayPicker(selection: $weekdays, identifierPrefix: "habit.weekday")
                } header: { Text(model.text(.frequency)) } footer: { Text(model.text(.habitScheduleNote)) }
            }
            .paceFormStyle()
            .navigationTitle(model.text(existing == nil ? .newHabit : .editHabit)).navigationBarTitleDisplayMode(.inline)
            .onAppear { if !initialized { targetText = model.inputNumber(existing?.target ?? 1); initialized = true } }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.cancel)) { dismiss() }.accessibilityIdentifier("cancelHabit") }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.text(.save)) {
                        var habit = existing ?? Habit(title: title)
                        habit.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        habit.goalType = kind; habit.target = target ?? 1; habit.weekdays = weekdays
                        if model.saveHabit(habit) { dismiss() }
                    }.disabled(!valid).accessibilityIdentifier("saveHabit")
                }
            }
        }
    }
}

struct HabitsView: View {
    @Environment(AppModel.self) private var model
    @State private var add = false

    var body: some View {
        PaceSubpage(title: model.text(.habits)) {
            Button { add = true } label: { PaceSquareIcon(systemImage: "plus") }
                .buttonStyle(.plain).accessibilityLabel(model.text(.newHabit)).accessibilityIdentifier("habits.add")
        } content: {
            if model.activeHabits.isEmpty {
                PaceCard {
                    PaceEmptyState(systemImage: "checklist", title: model.text(.noHabits), message: model.text(.welcomeDetail)) {
                        Button(model.text(.newHabit)) { add = true }.buttonStyle(PaceButtonStyle(kind: .secondary))
                    }
                }
            }
            ForEach(model.activeHabits) { habit in
                NavigationLink(value: AppRoute.habit(habit.id)) {
                    PaceSettingsRowLabel(systemImage: model.habitIcon(habit.goalType), title: habit.title,
                                         subtitle: model.habitScheduleSummary(habit),
                                         value: model.habitStreak(habit) > 0 ? "🔥 " + model.number(Double(model.habitStreak(habit))) : nil)
                }
                .buttonStyle(.plain).accessibilityIdentifier("habit.open." + habit.title)
            }
            let archived = model.state.habits.filter(\.isArchived)
            if !archived.isEmpty {
                PaceSectionTitle(model.pathText(.archived))
                ForEach(archived) { habit in
                    NavigationLink(value: AppRoute.habit(habit.id)) {
                        PaceSettingsRowLabel(systemImage: "archivebox", title: habit.title, subtitle: model.goalName(habit.goalType))
                    }.buttonStyle(.plain)
                }
                Text(model.text(.archiveHelp)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
            }
        }
        .sheet(isPresented: $add) { HabitEditor() }
    }
}

struct HabitDetailContent: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let habitID: UUID
    @State private var edit = false
    @State private var record = false
    @State private var confirmArchive = false
    private var habit: Habit? { model.state.habits.first { $0.id == habitID } }

    var body: some View {
        PaceSubpage(title: habit?.title ?? model.text(.habits), subtitle: habit.map { model.goalName($0.goalType) }) {
            if let habit, !habit.isArchived {
                Button { edit = true } label: { PaceSquareIcon(systemImage: "pencil") }
                    .buttonStyle(.plain).accessibilityLabel(model.text(.edit)).accessibilityIdentifier("editHabit")
            }
        } content: {
            if let habit {
                let today = model.state.completions.first { $0.habitID == habitID && $0.day == DayKey(date: model.today) }
                PaceCard {
                    VStack(alignment: .leading, spacing: PaceSpacing.s) {
                        HStack(alignment: .center, spacing: PaceSpacing.m) {
                            VStack(alignment: .leading, spacing: PaceSpacing.xxs) {
                                Text(model.text(.actualValue)).font(.headline)
                                Text(model.number(today?.actualValue ?? 0)).font(.system(size: 48, weight: .bold)).monospacedDigit()
                                Text(model.text(.target) + ": " + model.number(today?.targetSnapshot ?? habit.target) + (habit.goalType == .duration ? " " + model.text(.minutes) : ""))
                                    .font(.subheadline).foregroundStyle(PaceColor.textSecondary)
                            }
                            Spacer(minLength: PaceSpacing.xs)
                            PaceRing(progress: today?.progress ?? 0, diameter: 92, lineWidth: 11, centerText: model.percent(today?.progress ?? 0))
                        }
                        if !habit.isArchived {
                            Button(model.text(.recordProgress)) { record = true }
                                .buttonStyle(PaceButtonStyle()).disabled(!habit.isDue(on: model.today))
                                .accessibilityIdentifier("habit.record")
                            if !habit.isDue(on: model.today) { Text(model.text(.notScheduled)).font(.footnote).foregroundStyle(PaceColor.textSecondary) }
                        }
                    }
                }
                HStack(spacing: PaceSpacing.xs) {
                    PaceStatTile(value: model.number(Double(model.habitStreak(habit))), label: model.text(.streak), systemImage: "flame")
                    PaceStatTile(value: model.number(Double(model.state.completions.filter { $0.habitID == habitID && $0.isComplete }.count)),
                                 label: model.text(.completed), systemImage: "checkmark.circle")
                }
                PaceCard {
                    VStack(alignment: .leading, spacing: PaceSpacing.s) {
                        Text(model.text(.scheduledDays)).font(.headline)
                        HStack(spacing: PaceSpacing.xxs) {
                            ForEach(model.weekdays, id: \.self) { day in
                                let on = habit.weekdays.contains(day)
                                Text(model.weekdayShort(day))
                                    .font(.caption.weight(.semibold))
                                    .frame(maxWidth: .infinity, minHeight: 32)
                                    .foregroundStyle(on ? PaceColor.onSelection : PaceColor.textSecondary)
                                    .background(on ? PaceColor.selectionFill : PaceColor.fieldBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .accessibilityLabel(model.weekday(day))
                                    .accessibilityAddTraits(on ? .isSelected : [])
                            }
                        }
                    }
                }
                if !habit.isArchived { ReminderSection(target: .habit(habitID), defaultWeekdays: habit.weekdays) }
                PaceSectionTitle(model.text(.history))
                let entries = model.state.completions.filter { $0.habitID == habitID }.sorted { $0.day > $1.day }
                PaceCard {
                    VStack(alignment: .leading, spacing: PaceSpacing.s) {
                        if entries.isEmpty { Text(model.text(.noHistory)).foregroundStyle(PaceColor.textSecondary) }
                        ForEach(entries) { entry in
                            HStack(alignment: .center, spacing: PaceSpacing.s) {
                                Image(systemName: entry.isComplete ? "checkmark.circle.fill" : "circle.lefthalf.filled").foregroundStyle(PaceColor.accent)
                                Text(model.dayLabel(entry.day)).font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(model.number(entry.actualValue) + " / " + model.number(entry.targetSnapshot) + (entry.goalTypeSnapshot == .duration ? " " + model.text(.minutes) : ""))
                                    .font(.subheadline).monospacedDigit().foregroundStyle(PaceColor.textSecondary)
                            }
                        }
                        Text(model.text(.historyNote)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                    }
                }
                if !habit.isArchived {
                    Button(model.text(.archive)) { confirmArchive = true }.buttonStyle(PaceButtonStyle(kind: .destructive))
                }
            }
        }
        .sheet(isPresented: $edit) { if let habit { HabitEditor(existing: habit) } }
        .sheet(isPresented: $record) { if let habit { RecordEditor(habit: habit) } }
        .confirmationDialog(model.text(.confirmArchive), isPresented: $confirmArchive, titleVisibility: .visible) {
            Button(model.text(.archive), role: .destructive) { if let habit, model.archiveHabit(habit) { dismiss() } }
            Button(model.text(.cancel), role: .cancel) { }
        } message: { Text(model.text(.archiveMessage)) }
    }
}

struct RecordEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let habit: Habit
    @State private var valueText = "0"
    @State private var selectedDay: DayKey?
    @State private var dayChanged = false
    @State private var initialized = false
    private var value: Double? { model.parseNumber(valueText) }
    private var validValue: Bool { guard let value else { return false }; return value >= 0 && (kind != .count || value.rounded() == value) }
    private var kind: GoalType { model.dayGoalType(habit) }
    private var target: Double { model.dayTarget(habit) }

    var body: some View {
        NavigationStack {
            Form {
                SaveErrorBanner()
                Section(habit.title) {
                    if kind == .binary {
                        Toggle(model.text(.completed), isOn: Binding(get: { (value ?? 0) >= target }, set: { valueText = model.inputNumber($0 ? target : 0) }))
                    } else {
                        TextField(model.text(.actualValue), text: $valueText).keyboardType(kind == .count ? .numberPad : .decimalPad)
                            .accessibilityIdentifier("actualValue")
                    }
                    LabeledContent(model.text(.originalGoal), value: model.number(target) + (kind == .duration ? " " + model.text(.minutes) : ""))
                    Button(model.text(.reset)) { valueText = "0" }
                    if !validValue { Text(model.text(.validNumber)).font(.footnote).foregroundStyle(PaceColor.danger) }
                    if dayChanged { Text(model.text(.dayChanged)).foregroundStyle(PaceColor.danger) }
                }
                Section { Text(model.text(.historyNote)).font(.footnote).foregroundStyle(PaceColor.textSecondary) }
            }
            .paceFormStyle()
            .navigationTitle(model.text(.recordProgress)).navigationBarTitleDisplayMode(.inline)
            .onChange(of: model.today) { _, date in if let selectedDay, selectedDay != DayKey(date: date) { dayChanged = true } }
            .onAppear {
                if !initialized { model.refreshDay(); selectedDay = DayKey(date: model.today); valueText = model.inputNumber(model.completion(habit)?.actualValue ?? 0); initialized = true }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.text(.save)) {
                        let now = Date()
                        guard selectedDay == DayKey(date: now) else { dayChanged = true; return }
                        if let value, model.record(habit, value: value, on: now) { dismiss() }
                    }
                        .disabled(!validValue || dayChanged).accessibilityIdentifier("saveProgress")
                }
            }
        }
    }
}

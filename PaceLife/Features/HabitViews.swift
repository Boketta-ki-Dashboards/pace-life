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
                    Picker(model.text(.goal), selection: $kind) {
                        ForEach(GoalType.allCases, id: \.self) { Text(model.goalName($0)).tag($0) }
                    }.accessibilityIdentifier("habitGoal")
                    if kind != .binary {
                        TextField(model.text(.target), text: $targetText)
                            .keyboardType(kind == .count ? .numberPad : .decimalPad).accessibilityIdentifier("habitTarget")
                        if !validTarget { Text(model.text(.validNumber)).font(.footnote).foregroundStyle(PaceColor.danger) }
                        if kind == .duration { Text(model.text(.durationHelp)).font(.footnote).foregroundStyle(PaceColor.textSecondary) }
                    }
                } footer: { Text(model.text(.renameNote)) }
                Section {
                    ForEach(model.weekdays, id: \.self) { day in
                        Toggle(model.weekday(day), isOn: Binding(get: { weekdays.contains(day) }, set: { enabled in
                            if enabled { weekdays.insert(day) } else { weekdays.remove(day) }
                        }))
                    }
                } header: { Text(model.text(.frequency)) } footer: { Text(model.text(.habitScheduleNote)) }
            }
            .scrollContentBackground(.hidden).background(PaceColor.background)
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
    @Environment(\.dismiss) private var dismiss
    @State private var add = false

    var body: some View {
        NavigationStack {
            List {
                SaveErrorBanner()
                ForEach(model.activeHabits) { habit in
                    NavigationLink { HabitDetailContent(habitID: habit.id) } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(habit.title)
                            Text(model.goalName(habit.goalType)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                        }
                    }
                }
                if model.activeHabits.isEmpty { Text(model.text(.noHabits)).foregroundStyle(PaceColor.textSecondary) }
                let archived = model.state.habits.filter(\.isArchived)
                if !archived.isEmpty {
                    Section {
                        ForEach(archived) { habit in
                            NavigationLink { HabitDetailContent(habitID: habit.id) } label: { Label(habit.title, systemImage: "archivebox") }
                        }
                    } footer: { Text(model.text(.archiveHelp)) }
                }
            }
            .scrollContentBackground(.hidden).background(PaceColor.background)
            .navigationTitle(model.text(.habits)).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.done)) { dismiss() } }
                ToolbarItem(placement: .primaryAction) { Button { add = true } label: { Image(systemName: "plus") }.accessibilityLabel(model.text(.newHabit)) }
            }
            .sheet(isPresented: $add) { HabitEditor() }
        }
    }
}

struct HabitDetail: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let habitID: UUID
    var body: some View {
        NavigationStack {
            HabitDetailContent(habitID: habitID)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button(model.text(.done)) { dismiss() } } }
        }
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
        Group {
            if let habit {
                List {
                    SaveErrorBanner()
                    Section {
                        LabeledContent(model.text(.goal), value: model.goalName(habit.goalType))
                        LabeledContent(model.text(.target), value: model.number(habit.target) + (habit.goalType == .duration ? " " + model.text(.minutes) : ""))
                        Text(model.weekdays.filter { habit.weekdays.contains($0) }.map { model.weekday($0) }.joined(separator: ", "))
                            .font(.footnote).foregroundStyle(PaceColor.textSecondary)
                        if !habit.isArchived {
                            Button(model.text(.recordProgress)) { record = true }.disabled(!habit.isDue(on: model.today))
                            if !habit.isDue(on: model.today) { Text(model.text(.notScheduled)).font(.footnote).foregroundStyle(PaceColor.textSecondary) }
                            Button(model.text(.edit)) { edit = true }
                        }
                    }
                    Section {
                        let entries = model.state.completions.filter { $0.habitID == habitID }.sorted { $0.day > $1.day }
                        if entries.isEmpty { Text(model.text(.noHistory)).foregroundStyle(PaceColor.textSecondary) }
                        ForEach(entries) { entry in
                            HStack(alignment: .top) {
                                Image(systemName: entry.isComplete ? "checkmark.circle.fill" : "circle.lefthalf.filled").foregroundStyle(PaceColor.accent)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dayLabel(entry.day)).font(.headline)
                                    Text(model.number(entry.actualValue) + " / " + model.number(entry.targetSnapshot) + (entry.goalTypeSnapshot == .duration ? " " + model.text(.minutes) : ""))
                                        .font(.callout).foregroundStyle(PaceColor.textSecondary)
                                }
                            }
                        }
                    } header: { Text(model.text(.history)) } footer: { Text(model.text(.historyNote)) }
                    if !habit.isArchived {
                        Section { Button(model.text(.archive), role: .destructive) { confirmArchive = true } }
                    }
                }
                .scrollContentBackground(.hidden).background(PaceColor.background)
                .navigationTitle(habit.title).navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $edit) { HabitEditor(existing: habit) }
                .sheet(isPresented: $record) { RecordEditor(habit: habit) }
                .confirmationDialog(model.text(.confirmArchive), isPresented: $confirmArchive, titleVisibility: .visible) {
                    Button(model.text(.archive), role: .destructive) { if model.archiveHabit(habit) { dismiss() } }
                    Button(model.text(.cancel), role: .cancel) { }
                } message: { Text(model.text(.archiveMessage)) }
            }
        }
    }

    private func dayLabel(_ key: DayKey) -> String {
        let parser = DateFormatter(); parser.locale = Locale(identifier: "en_US_POSIX")
        parser.calendar = Calendar(identifier: .gregorian); parser.timeZone = TimeZone(secondsFromGMT: 0); parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: key.rawValue) else { return key.rawValue }
        let formatter = DateFormatter(); formatter.locale = model.locale
        formatter.timeZone = TimeZone(secondsFromGMT: 0); formatter.dateStyle = .medium
        return formatter.string(from: date)
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
    private var kind: GoalType { model.completion(habit)?.goalTypeSnapshot ?? habit.goalType }
    private var target: Double { model.completion(habit)?.targetSnapshot ?? habit.target }

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
            .scrollContentBackground(.hidden).background(PaceColor.background)
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

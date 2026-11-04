import SwiftUI
import PaceLifeCore

struct PathsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var creating = false
    var body: some View {
        NavigationStack {
            List {
                SaveErrorBanner()
                if model.state.paths.isEmpty { Text(model.pathText(.noPaths)) }
                ForEach(PathStatus.allCases, id: \.self) { status in
                    let paths = model.state.paths.filter { $0.status == status }
                    if !paths.isEmpty {
                        Section(model.pathStatusName(status)) {
                            ForEach(paths) { path in
                                NavigationLink { PathDetail(pathID: path.id) } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(path.title).font(.headline)
                                        ProgressView(value: model.state.pathProgress(path)).tint(PaceColor.accent)
                                    }
                                }.accessibilityIdentifier("path.open." + path.title)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden).background(PaceColor.background)
            .navigationTitle("Life Paths").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.done)) { dismiss() }.accessibilityIdentifier("closePaths") }
                ToolbarItem(placement: .primaryAction) {
                    Button { creating = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel(model.pathText(.newPath)).accessibilityIdentifier("addPath")
                }
            }
            .sheet(isPresented: $creating) { PathEditor() }
        }
    }
}

struct PathDetail: View {
    @Environment(AppModel.self) private var model
    let pathID: UUID
    @State private var editing = false
    @State private var recording: PathMilestone?
    private var path: LifePath? { model.state.paths.first { $0.id == pathID } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SaveErrorBanner()
                if let path {
                    PaceProgressRing(progress: model.state.pathProgress(path), value: model.state.pathProgress(path).formatted(.percent.locale(model.locale).precision(.fractionLength(0))), label: model.text(.progress))
                    Text(path.notes)
                    Text(path.category).foregroundStyle(PaceColor.textSecondary)
                    LabeledContent(model.pathText(.startDate), value: model.dayLabel(path.startDay))
                    if let day = path.targetDay { LabeledContent(model.pathText(.targetDate), value: model.dayLabel(day)) }
                    LabeledContent(model.pathText(.status), value: model.pathStatusName(path.status))
                    if let day = path.completedDay { LabeledContent(model.pathText(.completedDate), value: model.dayLabel(day)) }
                    ForEach(path.milestones) { milestone in milestoneCard(milestone, in: path) }
                    Text(model.pathText(.contributionRule)).font(.footnote)
                    Text(model.pathText(.routineRule)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                    Button(model.text(.edit)) { editing = true }.buttonStyle(PaceButtonStyle(kind: .secondary))
                    if path.status == .active {
                        Button(model.pathText(.finish)) { model.setPathStatus(pathID, .completed) }
                            .buttonStyle(PaceButtonStyle()).disabled(model.state.pathProgress(path) < 1)
                        Button(model.pathText(.paused)) { model.setPathStatus(pathID, .paused) }
                    } else {
                        Button(model.pathText(.resume)) { model.setPathStatus(pathID, .active) }.buttonStyle(PaceButtonStyle())
                    }
                    if path.status != .archived { Button(model.text(.archive)) { model.setPathStatus(pathID, .archived) } }
                }
            }.padding(16)
        }
        .background(PaceColor.background).navigationTitle(path?.title ?? "Life Paths").navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden(false)
        .background { NativeBackSwipe().frame(width: 0, height: 0).allowsHitTesting(false) }
        .sheet(isPresented: $editing) { if let path { PathEditor(path: path) } }
        .sheet(item: $recording) { PathEntryEditor(milestone: $0) }
    }
    private func milestoneCard(_ milestone: PathMilestone, in path: LifePath) -> some View {
        PaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(milestone.title).font(.headline)
                let actual = model.state.milestoneValue(milestone, in: path)
                Text(model.number(actual) + " / " + model.number(milestone.target) + (milestone.goalType == .duration ? " " + model.text(.minutes) : ""))
                    .accessibilityIdentifier("milestone.value." + milestone.title)
                ProgressView(value: min(1, actual / milestone.target)).tint(PaceColor.accent)
                if let id = milestone.habitID, let habit = model.state.habits.first(where: { $0.id == id }) {
                    NavigationLink { HabitDetailContent(habitID: id) } label: { Label(habit.title, systemImage: "link") }
                } else if let id = milestone.routineID, let routine = model.state.routines.first(where: { $0.id == id }) {
                    NavigationLink { RoutineDetail(routineID: id) } label: { Label(routine.title, systemImage: "list.bullet.rectangle") }
                } else {
                    Button(model.text(.recordProgress)) { recording = milestone }.disabled(path.status != .active)
                        .accessibilityIdentifier("recordMilestone." + milestone.title)
                }
                let days = Set(model.state.pathEntries.filter { $0.milestoneID == milestone.id }.map(\.day)
                    + model.state.completions.filter { $0.habitID == milestone.habitID && $0.goalTypeSnapshot == milestone.goalType && $0.day >= path.startDay }.map(\.day)
                    + model.state.routineSessions.filter { $0.routineID == milestone.routineID && $0.day >= path.startDay }.map(\.day)).sorted(by: >)
                ForEach(days, id: \.self) { day in
                    LabeledContent(model.dayLabel(day), value: model.number(model.state.milestoneValue(milestone, in: path, through: day)))
                        .font(.footnote).foregroundStyle(PaceColor.textSecondary)
                }
            }
        }
    }
}

private struct MilestoneDraft: Identifiable {
    let id: UUID
    var title: String
    var kind: GoalType
    var target: String
    var habitID: UUID?
    var routineID: UUID?
    let isExisting: Bool
    init(_ source: PathMilestone? = nil) {
        id = source?.id ?? UUID(); title = source?.title ?? ""; kind = source?.goalType ?? .binary
        target = source.map { String($0.target) } ?? "1"; habitID = source?.habitID; routineID = source?.routineID; isExisting = source != nil
    }
}
struct PathEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let existing: LifePath?
    @State private var title: String
    @State private var notes: String
    @State private var category: String
    @State private var targetEnabled: Bool
    @State private var targetDate: Date
    @State private var milestones: [MilestoneDraft]
    @State private var initialized = false
    @State private var editMode: EditMode = .inactive
    init(path: LifePath? = nil) {
        existing = path; _title = State(initialValue: path?.title ?? "")
        _notes = State(initialValue: path?.notes ?? ""); _category = State(initialValue: path?.category ?? "")
        _targetEnabled = State(initialValue: path?.targetDay != nil)
        _targetDate = State(initialValue: Date())
        _milestones = State(initialValue: path?.milestones.map { MilestoneDraft($0) } ?? [MilestoneDraft()])
    }
    private var valid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !milestones.isEmpty
            && milestones.allSatisfy { draft in
                guard !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      let target = model.parseNumber(draft.target), target > 0 else { return false }
                return draft.kind == .duration || (draft.kind == .binary ? target == 1 : target.rounded() == target)
            }
    }
    var body: some View {
        NavigationStack {
            Form {
                SaveErrorBanner()
                Section {
                    TextField(model.text(.name), text: $title).accessibilityIdentifier("pathTitle")
                    TextField(model.routineText(.notes), text: $notes, axis: .vertical)
                    TextField(model.pathText(.category), text: $category)
                    Toggle(model.pathText(.targetDate), isOn: $targetEnabled)
                    if targetEnabled { DatePicker(model.pathText(.targetDate), selection: $targetDate, displayedComponents: .date) }
                }
                milestonesSection
                Text(model.pathText(.contributionRule)).font(.footnote)
                Text(model.pathText(.routineRule)).font(.footnote)
            }
            .environment(\.editMode, $editMode)
            .scrollContentBackground(.hidden).background(PaceColor.background)
            .navigationTitle(model.pathText(existing == nil ? .newPath : .editPath)).navigationBarTitleDisplayMode(.inline)
            .onAppear {
                guard !initialized else { return }; initialized = true
                if let existing {
                    for index in milestones.indices { milestones[index].target = model.inputNumber(existing.milestones[index].target) }
                    if let day = existing.targetDay {
                        let parts = day.rawValue.split(separator: "-").compactMap { Int($0) }
                        if parts.count == 3 { targetDate = Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])) ?? Date() }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button(model.text(.save), action: save).disabled(!valid).accessibilityIdentifier("savePath") }
                ToolbarItem(placement: .bottomBar) { EditButton().environment(\.editMode, $editMode) }
            }
        }
    }
    private var milestonesSection: some View {
        Section(model.pathText(.milestones)) {
            ForEach($milestones) { $draft in
                VStack(alignment: .leading, spacing: 12) {
                    TextField(model.text(.name), text: $draft.title).accessibilityIdentifier("milestoneTitle")
                    if !draft.isExisting {
                        Picker(model.text(.goal), selection: $draft.kind) {
                            ForEach(GoalType.allCases, id: \.self) { Text(model.goalName($0)).tag($0) }
                        }.onChange(of: draft.kind) { _, _ in draft.habitID = nil; draft.routineID = nil; draft.target = "1" }
                        Picker(model.pathText(.source), selection: Binding(get: {
                            if let id = draft.habitID { return "habit:" + id.uuidString }
                            if let id = draft.routineID { return "routine:" + id.uuidString }
                            return "manual"
                        }, set: { selection in
                            draft.habitID = selection.hasPrefix("habit:") ? UUID(uuidString: String(selection.dropFirst(6))) : nil
                            draft.routineID = selection.hasPrefix("routine:") ? UUID(uuidString: String(selection.dropFirst(8))) : nil
                        })) {
                            Text(model.pathText(.manual)).tag("manual")
                            ForEach(model.activeHabits.filter { $0.goalType == draft.kind }) {
                                Text($0.title + " · " + model.text(.habits)).tag("habit:" + $0.id.uuidString)
                            }
                            if draft.kind != .duration {
                                ForEach(model.state.routines.filter { !$0.isArchived }) {
                                    Text($0.title + " · " + model.text(.routines)).tag("routine:" + $0.id.uuidString)
                                }
                            }
                        }.accessibilityIdentifier("milestoneSource")
                    } else { Text(model.goalName(draft.kind)).font(.footnote) }
                    if draft.kind != .binary {
                        TextField(model.text(.target), text: $draft.target).keyboardType(.decimalPad)
                    }
                }
                .deleteDisabled(draft.isExisting)
            }.onMove { milestones.move(fromOffsets: $0, toOffset: $1) }
                .onDelete { indices in
                    milestones.remove(atOffsets: IndexSet(indices.filter { !milestones[$0].isExisting }))
                }
            Button(model.pathText(.addMilestone)) { milestones.append(MilestoneDraft()) }.accessibilityIdentifier("addMilestone")
        }
    }
    private func save() {
        guard valid else { return }
        let items = milestones.map { PathMilestone(id: $0.id, title: $0.title, goalType: $0.kind, target: model.parseNumber($0.target) ?? 1, habitID: $0.habitID, routineID: $0.routineID) }
        var path = existing ?? LifePath(title: title, milestones: items)
        path.title = title; path.notes = notes; path.category = category; path.milestones = items
        path.targetDay = targetEnabled ? DayKey(date: targetDate) : nil
        if model.savePath(path) { dismiss() }
    }
}

struct PathEntryEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let milestone: PathMilestone
    @State private var value = "0"
    @State private var day = DayKey(date: Date())
    var body: some View {
        NavigationStack {
            Form {
                SaveErrorBanner()
                Text(milestone.title).font(.headline)
                if milestone.goalType == .binary {
                    Toggle(model.text(.completed), isOn: Binding(get: { model.parseNumber(value) == 1 }, set: { value = $0 ? "1" : "0" })).accessibilityIdentifier("pathEntryComplete")
                } else { TextField(model.pathText(.todayValue), text: $value).keyboardType(.decimalPad) }
                if day != DayKey(date: model.today) { Text(model.text(.dayChanged)).foregroundStyle(PaceColor.danger) }
            }
            .navigationTitle(model.pathText(.todayValue)).navigationBarTitleDisplayMode(.inline)
            .onAppear {
                day = DayKey(date: Date())
                value = model.inputNumber(model.state.pathEntries.first { $0.milestoneID == milestone.id && $0.day == day }?.value ?? 0)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.text(.save)) {
                        guard day == DayKey(date: Date()), let number = model.parseNumber(value) else { return }
                        if model.recordPathEntry(milestone.id, value: number) { dismiss() }
                    }.disabled(model.parseNumber(value) == nil || day != DayKey(date: model.today)).accessibilityIdentifier("savePathEntry")
                }
            }
        }
    }
}

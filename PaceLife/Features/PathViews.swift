import SwiftUI
import PaceLifeCore

struct PathsView: View {
    @Environment(AppModel.self) private var model
    @State private var creating = false
    var body: some View {
        PaceSubpage(title: model.pathText(.paths), subtitle: model.text(.pathsDetail)) {
            Button { creating = true } label: { PaceSquareIcon(systemImage: "plus") }
                .buttonStyle(.plain)
                .accessibilityLabel(model.pathText(.newPath)).accessibilityIdentifier("addPath")
        } content: {
            if model.state.paths.isEmpty {
                PaceCard {
                    PaceEmptyState(systemImage: "point.topleft.down.to.point.bottomright.curvepath", title: model.pathText(.paths), message: model.pathText(.noPaths)) {
                        Button(model.pathText(.newPath)) { creating = true }.buttonStyle(PaceButtonStyle(kind: .secondary))
                    }
                }
            }
            ForEach(PathStatus.allCases, id: \.self) { status in
                let paths = model.state.paths.filter { $0.status == status }
                if !paths.isEmpty {
                    PaceSectionTitle(model.pathStatusName(status))
                    ForEach(paths) { path in
                        NavigationLink(value: AppRoute.path(path.id)) { PathRowCard(path: path) }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("path.open." + path.title)
                    }
                }
            }
        }
        .sheet(isPresented: $creating) { PathEditor() }
    }
}

/// Overview card of one path: progress, status and the next open milestone.
struct PathRowCard: View {
    @Environment(AppModel.self) private var model
    let path: LifePath
    var body: some View {
        let progress = model.state.pathProgress(path)
        PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(path.title).font(.headline).foregroundStyle(PaceColor.textPrimary)
                        Text([path.category, model.pathStatusName(path.status)].filter { !$0.isEmpty }.joined(separator: " · "))
                            .font(.footnote).foregroundStyle(PaceColor.textSecondary)
                    }
                    Spacer(minLength: PaceSpacing.xs)
                    Text(model.percent(progress)).font(.title2.weight(.heavy)).monospacedDigit()
                        .foregroundStyle(PaceColor.textPrimary)
                    PaceChevron()
                }
                PaceProgressBar(progress: progress)
                if let next = model.nextMilestone(in: path) {
                    Label(model.pathText(.nextMilestone) + ": " + next.title, systemImage: "flag")
                        .font(.footnote).foregroundStyle(PaceColor.textSecondary).lineLimit(2)
                }
            }
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
        PaceSubpage(title: path?.title ?? model.pathText(.paths), subtitle: path.map { model.pathStatusName($0.status) + ($0.category.isEmpty ? "" : " · " + $0.category) }) {
            if path != nil {
                Button { editing = true } label: { PaceSquareIcon(systemImage: "pencil") }
                    .buttonStyle(.plain).accessibilityLabel(model.text(.edit)).accessibilityIdentifier("editPath")
            }
        } content: {
            if let path {
                hero(path)
                if !path.notes.isEmpty { PaceCard { Text(path.notes).font(.body).foregroundStyle(PaceColor.textPrimary) } }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: PaceSpacing.xs), GridItem(.flexible(), spacing: PaceSpacing.xs)], spacing: PaceSpacing.xs) {
                    PaceStatTile(value: model.dayLabel(path.startDay), label: model.pathText(.startDate), systemImage: "calendar")
                    if let day = path.targetDay { PaceStatTile(value: model.dayLabel(day), label: model.pathText(.targetDate), systemImage: "flag.checkered") }
                    if let day = path.completedDay { PaceStatTile(value: model.dayLabel(day), label: model.pathText(.completedDate), systemImage: "checkmark.seal") }
                }
                PaceSectionTitle(model.pathText(.milestones))
                ForEach(Array(path.milestones.enumerated()), id: \.element.id) { index, milestone in
                    milestoneCard(milestone, index: index, in: path)
                }
                VStack(alignment: .leading, spacing: PaceSpacing.xs) {
                    Text(model.pathText(.contributionRule))
                    Text(model.pathText(.routineRule))
                }
                .font(.footnote).foregroundStyle(PaceColor.textSecondary)
                VStack(spacing: PaceSpacing.xs) {
                    if path.status == .active {
                        Button(model.pathText(.finish)) { model.setPathStatus(pathID, .completed) }
                            .buttonStyle(PaceButtonStyle()).disabled(model.state.pathProgress(path) < 1)
                        Button(model.pathText(.paused)) { model.setPathStatus(pathID, .paused) }
                            .buttonStyle(PaceButtonStyle(kind: .secondary))
                    } else {
                        Button(model.pathText(.resume)) { model.setPathStatus(pathID, .active) }.buttonStyle(PaceButtonStyle())
                    }
                    if path.status != .archived {
                        Button(model.text(.archive)) { model.setPathStatus(pathID, .archived) }.buttonStyle(PaceButtonStyle(kind: .destructive))
                    }
                }
            } else {
                PaceCard { PaceEmptyState(systemImage: "questionmark.folder", title: model.pathText(.paths), message: model.text(.noHistory)) }
            }
        }
        .sheet(isPresented: $editing) { if let path { PathEditor(path: path) } }
        .sheet(item: $recording) { PathEntryEditor(milestone: $0) }
    }

    private func hero(_ path: LifePath) -> some View {
        let progress = model.state.pathProgress(path)
        let done = path.milestones.filter { model.state.milestoneValue($0, in: path) >= $0.target }.count
        return PaceCard {
            HStack(alignment: .center, spacing: PaceSpacing.m) {
                VStack(alignment: .leading, spacing: PaceSpacing.xs) {
                    Text(model.text(.progress)).font(.headline)
                    Text(model.percent(progress)).font(.system(size: 48, weight: .bold)).monospacedDigit()
                        .minimumScaleFactor(0.6).lineLimit(1)
                    Text(model.pathText(.milestonesDone, done, path.milestones.count))
                        .font(.subheadline).foregroundStyle(PaceColor.textSecondary)
                    PaceProgressBar(progress: progress)
                }
                PaceRing(progress: progress, diameter: 96, lineWidth: 11,
                         centerText: model.number(Double(done)) + "/" + model.number(Double(path.milestones.count)))
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func milestoneCard(_ milestone: PathMilestone, index: Int, in path: LifePath) -> some View {
        let actual = model.state.milestoneValue(milestone, in: path)
        let reached = actual >= milestone.target
        return HStack(alignment: .top, spacing: PaceSpacing.s) {
            ZStack {
                Circle().fill(reached ? PaceColor.goalReachedFill : PaceColor.accentSoft)
                if reached { Image(systemName: "checkmark").font(.footnote.weight(.bold)).foregroundStyle(PaceColor.onGoalReached) }
                else { Text(model.number(Double(index + 1))).font(.footnote.weight(.bold)).foregroundStyle(PaceColor.accentStrong) }
            }
            .frame(width: 28, height: 28)
            .padding(.top, PaceSpacing.m)
            .accessibilityHidden(true)
            PaceCard {
                VStack(alignment: .leading, spacing: PaceSpacing.s) {
                    Text(milestone.title).font(.headline)
                    Text(model.number(actual) + " / " + model.number(milestone.target) + (milestone.goalType == .duration ? " " + model.text(.minutes) : ""))
                        .font(.subheadline.weight(.semibold)).monospacedDigit()
                        .accessibilityIdentifier("milestone.value." + milestone.title)
                    PaceProgressBar(progress: min(1, actual / milestone.target), height: 6)
                    if let id = milestone.habitID, let habit = model.state.habits.first(where: { $0.id == id }) {
                        NavigationLink(value: AppRoute.habit(id)) { Label(habit.title, systemImage: "link") }
                            .buttonStyle(PaceLinkButtonStyle())
                    } else if let id = milestone.routineID, let routine = model.state.routines.first(where: { $0.id == id }) {
                        NavigationLink(value: AppRoute.routine(id)) { Label(routine.title, systemImage: "list.bullet.rectangle") }
                            .buttonStyle(PaceLinkButtonStyle())
                    } else {
                        Button { recording = milestone } label: { Label(model.text(.recordProgress), systemImage: "plus.circle") }
                            .buttonStyle(PaceLinkButtonStyle()).disabled(path.status != .active)
                            .accessibilityIdentifier("recordMilestone." + milestone.title)
                    }
                    let days = Set(model.state.pathEntries.filter { $0.milestoneID == milestone.id }.map(\.day)
                        + model.state.completions.filter { $0.habitID == milestone.habitID && $0.goalTypeSnapshot == milestone.goalType && $0.day >= path.startDay }.map(\.day)
                        + model.state.routineSessions.filter { $0.routineID == milestone.routineID && $0.day >= path.startDay }.map(\.day)).sorted(by: >)
                    ForEach(days.prefix(5), id: \.self) { day in
                        HStack {
                            Text(model.dayLabel(day))
                            Spacer()
                            Text(model.number(model.state.milestoneValue(milestone, in: path, through: day))).monospacedDigit()
                        }
                        .font(.footnote).foregroundStyle(PaceColor.textSecondary)
                    }
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
            .paceFormStyle()
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

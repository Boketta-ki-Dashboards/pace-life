import SwiftUI
import PaceLifeCore

struct RoutinesView: View {
    @Environment(AppModel.self) private var model
    @State private var creating = false
    @State private var showArchive = false
    var body: some View {
        PaceSubpage(title: model.routineText(.routines)) {
            Button { creating = true } label: { PaceSquareIcon(systemImage: "plus") }
                .buttonStyle(.plain)
                .accessibilityLabel(model.routineText(.newRoutine)).accessibilityIdentifier("addRoutine")
        } content: {
            PaceSegmentedControl(selection: $showArchive, options: [(false, model.pathText(.active)), (true, model.pathText(.archived))])
            let routines = model.state.routines.filter { $0.isArchived == showArchive }
            if routines.isEmpty {
                PaceCard {
                    PaceEmptyState(systemImage: "list.bullet.rectangle", title: model.routineText(.routines), message: model.routineText(.noRoutines)) {
                        if !showArchive {
                            Button(model.routineText(.newRoutine)) { creating = true }.buttonStyle(PaceButtonStyle(kind: .secondary))
                        }
                    }
                }
            }
            ForEach(routines) { routine in
                NavigationLink(value: AppRoute.routine(routine.id)) { RoutineRowCard(routine: routine) }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("routine.open." + routine.title)
            }
        }
        .sheet(isPresented: $creating) { RoutineEditor() }
    }
}

struct RoutineRowCard: View {
    @Environment(AppModel.self) private var model
    let routine: Routine
    var body: some View {
        let session = model.routineSession(routine.id)
        PaceCard {
            HStack(spacing: PaceSpacing.s) {
                PaceRing(progress: session?.progress ?? 0, diameter: 44, lineWidth: 5)
                    .overlay { Image(systemName: session?.isComplete == true ? "checkmark" : "list.bullet").font(.caption.weight(.bold)).foregroundStyle(PaceColor.accentStrong) }
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(routine.title).font(.headline).foregroundStyle(PaceColor.textPrimary)
                    Text(([model.routineTime(routine)].compactMap { $0 } + [model.routineText(.steps) + ": " + model.number(Double(routine.steps.count))]).joined(separator: " · "))
                        .font(.footnote).foregroundStyle(PaceColor.textSecondary)
                }
                Spacer(minLength: PaceSpacing.xs)
                if let session {
                    Text(model.number(Double(session.completedStepIDs.count)) + "/" + model.number(Double(session.steps.count)))
                        .font(.subheadline.weight(.semibold)).monospacedDigit()
                }
                PaceChevron()
            }
        }
    }
}

struct RoutineDetail: View {
    @Environment(AppModel.self) private var model
    let routineID: UUID
    @State private var editing = false
    @State private var confirmArchive = false
    private var routine: Routine? { model.state.routines.first { $0.id == routineID } }
    var body: some View {
        PaceSubpage(title: routine?.title ?? model.routineText(.routines), subtitle: routine.flatMap { model.routineTime($0) }) {
            if routine != nil {
                Button { editing = true } label: { PaceSquareIcon(systemImage: "pencil") }
                    .buttonStyle(.plain).accessibilityLabel(model.text(.edit)).accessibilityIdentifier("editRoutine")
            }
        } content: {
            if let routine {
                if !routine.notes.isEmpty { PaceCard { Text(routine.notes).foregroundStyle(PaceColor.textSecondary) } }
                if let session = model.routineSession(routineID) {
                    sessionCard(session)
                } else if !routine.isArchived {
                    PaceCard {
                        VStack(alignment: .leading, spacing: PaceSpacing.s) {
                            PaceCardHeader(title: model.routineText(.steps), chevron: false)
                            ForEach(Array(routine.steps.enumerated()), id: \.element.id) { index, step in
                                HStack(spacing: PaceSpacing.s) {
                                    Text(model.number(Double(index + 1))).font(.footnote.weight(.bold)).foregroundStyle(PaceColor.accentStrong)
                                        .frame(width: 26, height: 26).background(PaceColor.accentSoft, in: Circle())
                                    Text(step.title)
                                    Spacer()
                                    if let minutes = step.minutes { Text(model.number(Double(minutes)) + " " + model.text(.minutes)).font(.footnote).foregroundStyle(PaceColor.textSecondary) }
                                }
                            }
                            Button(model.routineText(.start)) { model.startRoutine(routineID) }
                                .buttonStyle(PaceButtonStyle())
                                .disabled(!model.dueRoutines.contains(where: { $0.id == routineID }))
                                .accessibilityIdentifier("startRoutine")
                            if !model.dueRoutines.contains(where: { $0.id == routineID }) {
                                Text(model.text(.notScheduled)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                            }
                        }
                    }
                }
                if !routine.isArchived { ReminderSection(target: .routine(routineID), defaultWeekdays: routine.weekdays) }
                Text(model.routineText(.snapshotNote)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                let history = model.state.routineSessions.filter { $0.routineID == routineID }.sorted { $0.day > $1.day }
                if !history.isEmpty { PaceSectionTitle(model.routineText(.history)) }
                ForEach(history) { session in
                    PaceCard {
                        VStack(alignment: .leading, spacing: PaceSpacing.xs) {
                            HStack {
                                Text(model.dayLabel(session.day)).font(.headline)
                                Spacer()
                                Text(model.number(Double(session.completedStepIDs.count)) + " / " + model.number(Double(session.steps.count)))
                                    .font(.subheadline.weight(.semibold)).monospacedDigit()
                            }
                            Text(session.titleSnapshot).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                            ForEach(session.steps) { step in
                                Label(step.title, systemImage: session.completedStepIDs.contains(step.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.subheadline)
                                    .foregroundStyle(session.completedStepIDs.contains(step.id) ? PaceColor.accent : PaceColor.textSecondary)
                            }
                        }
                    }
                }
                if !routine.isArchived {
                    Button(model.text(.archive)) { confirmArchive = true }.buttonStyle(PaceButtonStyle(kind: .destructive))
                }
            }
        }
        .sheet(isPresented: $editing) { if let routine { RoutineEditor(routine: routine) } }
        .confirmationDialog(model.routineText(.archiveNote), isPresented: $confirmArchive) {
            Button(model.text(.archive), role: .destructive) { model.archiveRoutine(routineID) }
        }
    }
    private func sessionCard(_ session: RoutineSession) -> some View {
        PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                HStack(alignment: .center, spacing: PaceSpacing.m) {
                    VStack(alignment: .leading, spacing: PaceSpacing.xxs) {
                        Text(session.titleSnapshot).font(.title3.weight(.semibold))
                        Text(model.number(Double(session.completedStepIDs.count)) + " / " + model.number(Double(session.steps.count)))
                            .font(.system(size: 34, weight: .bold)).monospacedDigit()
                            .accessibilityIdentifier("routine.progress")
                    }
                    Spacer(minLength: PaceSpacing.xs)
                    PaceRing(progress: session.progress, diameter: 80, lineWidth: 10, centerText: model.percent(session.progress))
                }
                PaceProgressBar(progress: session.progress)
                ForEach(session.steps) { step in
                    Toggle(isOn: Binding(get: { session.completedStepIDs.contains(step.id) }, set: { model.setRoutineStep(session, stepID: step.id, completed: $0) })) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title).font(.body)
                            if let minutes = step.minutes { Text(model.number(Double(minutes)) + " " + model.text(.minutes)).font(.footnote).foregroundStyle(PaceColor.textSecondary) }
                        }
                    }
                    .tint(PaceColor.accentStrong)
                    .frame(minHeight: 44)
                    .disabled(session.isPaused).accessibilityIdentifier("routine.step." + step.title)
                }
                if !session.isComplete {
                    Button(model.routineText(session.isPaused ? .resume : .pause)) { model.pauseRoutine(session.id, paused: !session.isPaused) }
                        .buttonStyle(PaceButtonStyle(kind: .secondary)).accessibilityIdentifier("pauseRoutine")
                }
            }
        }
    }
}

struct RoutineEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Routine
    @State private var editMode: EditMode = .inactive
    private let isNew: Bool
    init(routine: Routine? = nil) {
        isNew = routine == nil
        _draft = State(initialValue: routine ?? Routine(title: "", steps: [RoutineStep(title: "")]))
    }
    private var valid: Bool {
        !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !draft.weekdays.isEmpty && !draft.steps.isEmpty
            && draft.steps.allSatisfy { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    var body: some View {
        NavigationStack {
            Form {
                SaveErrorBanner()
                Section {
                    TextField(model.text(.name), text: $draft.title).accessibilityIdentifier("routineTitle")
                    TextField(model.routineText(.notes), text: $draft.notes, axis: .vertical)
                    Picker(model.routineText(.mode), selection: $draft.modeID) {
                        Text(model.routineText(.noMode)).tag(UUID?.none)
                        ForEach(model.state.modes) { Text($0.title).tag(Optional($0.id)) }
                    }
                }
                stepsSection
                Section(model.text(.frequency)) {
                    ForEach(model.weekdays, id: \.self) { day in
                        Toggle(model.weekday(day), isOn: Binding(get: { draft.weekdays.contains(day) }, set: {
                            if $0 { draft.weekdays.insert(day) } else { draft.weekdays.remove(day) }
                        }))
                    }
                    Toggle(model.routineText(.plannedTime), isOn: Binding(get: { draft.plannedMinute != nil }, set: { draft.plannedMinute = $0 ? 480 : nil }))
                    if draft.plannedMinute != nil {
                        DatePicker(model.routineText(.plannedTime), selection: Binding(get: {
                            Calendar.current.date(bySettingHour: (draft.plannedMinute ?? 480) / 60, minute: (draft.plannedMinute ?? 480) % 60, second: 0, of: model.today) ?? model.today
                        }, set: {
                            let c = Calendar.current.dateComponents([.hour, .minute], from: $0)
                            draft.plannedMinute = (c.hour ?? 0) * 60 + (c.minute ?? 0)
                        }), displayedComponents: .hourAndMinute)
                    }
                }
                if draft.isArchived { Toggle(model.text(.archive), isOn: $draft.isArchived) }
            }
            .environment(\.editMode, $editMode)
            .paceFormStyle()
            .navigationTitle(model.routineText(isNew ? .newRoutine : .editRoutine)).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.text(.save)) { if model.saveRoutine(draft) { dismiss() } }
                        .disabled(!valid).accessibilityIdentifier("saveRoutine")
                }
                ToolbarItem(placement: .bottomBar) { EditButton().environment(\.editMode, $editMode) }
            }
        }
    }
    private var stepsSection: some View {
        Section(model.routineText(.steps)) {
            ForEach($draft.steps) { $step in
                VStack(alignment: .leading) {
                    TextField(model.routineText(.stepTitle), text: $step.title).accessibilityIdentifier("routineStepTitle")
                    Toggle(model.routineText(.stepDuration), isOn: Binding(get: { step.minutes != nil }, set: { step.minutes = $0 ? 5 : nil }))
                    if step.minutes != nil {
                        Stepper(model.number(Double(step.minutes ?? 5)) + " " + model.text(.minutes), value: Binding(get: { step.minutes ?? 5 }, set: { step.minutes = $0 }), in: 1...1440)
                    }
                }
            }.onDelete { draft.steps.remove(atOffsets: $0) }
                .onMove { draft.steps.move(fromOffsets: $0, toOffset: $1) }
            Button(model.routineText(.addStep)) { draft.steps.append(RoutineStep(title: "")) }.accessibilityIdentifier("addRoutineStep")
        }
    }
}
